package com.sayan.h20remind

import android.content.ActivityNotFoundException
import android.content.Intent
import android.net.Uri
import androidx.activity.ComponentActivity
import androidx.health.connect.client.HealthConnectClient
import androidx.health.connect.client.PermissionController
import androidx.health.connect.client.permission.HealthPermission
import androidx.health.connect.client.records.HydrationRecord
import androidx.health.connect.client.records.metadata.DataOrigin
import androidx.health.connect.client.records.metadata.Metadata
import androidx.health.connect.client.request.ReadRecordsRequest
import androidx.health.connect.client.time.TimeRangeFilter
import androidx.health.connect.client.units.Volume
import androidx.lifecycle.lifecycleScope
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.time.Duration
import java.time.Instant
import java.time.ZoneOffset
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.launch

/**
 * Handles the `h20remind/health_connect` method channel: availability,
 * permissions, and reconciling the app's hydration log into Health Connect.
 */
class HealthConnectBridge(private val activity: ComponentActivity) : MethodChannel.MethodCallHandler {

    companion object {
        const val CHANNEL = "h20remind/health_connect"
        private const val PROVIDER_PACKAGE = "com.google.android.apps.healthdata"

        // Drinks are instantaneous, but Health Connect needs start < end.
        private val DRINK_DURATION: Duration = Duration.ofSeconds(1)
        private const val BATCH_SIZE = 500
    }

    private val permissions = setOf(
        HealthPermission.getReadPermission(HydrationRecord::class),
        HealthPermission.getWritePermission(HydrationRecord::class),
    )

    private var pendingPermissionResult: MethodChannel.Result? = null

    private val permissionLauncher = activity.registerForActivityResult(
        PermissionController.createRequestPermissionResultContract(),
    ) { granted ->
        pendingPermissionResult?.success(granted.containsAll(permissions))
        pendingPermissionResult = null
    }

    private val client by lazy { HealthConnectClient.getOrCreate(activity) }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "getStatus" -> result.success(status())
            "openInstallPage" -> result.success(openInstallPage())
            "openSettings" -> result.success(openSettings())
            "hasPermissions", "requestPermissions", "revokePermissions", "sync" ->
                activity.lifecycleScope.launch { handleAsync(call, result) }
            else -> result.notImplemented()
        }
    }

    private suspend fun handleAsync(call: MethodCall, result: MethodChannel.Result) {
        try {
            when (call.method) {
                "hasPermissions" -> result.success(hasPermissions())
                "requestPermissions" -> requestPermissions(result)
                "revokePermissions" -> {
                    client.permissionController.revokeAllPermissions()
                    result.success(null)
                }
                "sync" -> result.success(sync(call))
            }
        } catch (e: CancellationException) {
            throw e
        } catch (e: SecurityException) {
            result.error("permission_denied", e.message, null)
        } catch (e: Exception) {
            result.error("health_connect_error", e.message, null)
        }
    }

    private fun status(): String = when (HealthConnectClient.getSdkStatus(activity, PROVIDER_PACKAGE)) {
        HealthConnectClient.SDK_AVAILABLE -> "available"
        HealthConnectClient.SDK_UNAVAILABLE_PROVIDER_UPDATE_REQUIRED -> "updateRequired"
        else -> "unavailable"
    }

    private suspend fun hasPermissions(): Boolean =
        client.permissionController.getGrantedPermissions().containsAll(permissions)

    private suspend fun requestPermissions(result: MethodChannel.Result) {
        when {
            hasPermissions() -> result.success(true)
            pendingPermissionResult != null ->
                result.error("busy", "A permission request is already in progress", null)
            else -> {
                pendingPermissionResult = result
                permissionLauncher.launch(permissions)
            }
        }
    }

    /**
     * Makes this app's records in `[startMs, endMs)` whose client id starts
     * with `prefix` match `entries` exactly: inserts missing entries and
     * deletes records whose entry no longer exists.
     */
    private suspend fun sync(call: MethodCall): Map<String, Int> {
        val start = Instant.ofEpochMilli(call.requireLong("startMs"))
        val end = Instant.ofEpochMilli(call.requireLong("endMs"))
        val prefix = call.argument<String>("prefix")
            ?: throw IllegalArgumentException("Missing prefix")
        val entries = call.argument<List<Map<String, Any>>>("entries").orEmpty()
            .map { it.toRecord(prefix) }
            .filter { !it.startTime.isBefore(start) && it.startTime.isBefore(end) }

        val existing = readOwnRecords(start, end)
            .filter { it.metadata.clientRecordId?.startsWith(prefix) == true }
        val existingIds = existing.mapNotNull { it.metadata.clientRecordId }.toSet()
        val wantedIds = entries.mapNotNull { it.metadata.clientRecordId }.toSet()

        val toInsert = entries.filter { it.metadata.clientRecordId !in existingIds }
        val toDelete = existing.filter { it.metadata.clientRecordId !in wantedIds }.map { it.metadata.id }

        toInsert.chunked(BATCH_SIZE).forEach { client.insertRecords(it) }
        toDelete.chunked(BATCH_SIZE).forEach {
            client.deleteRecords(HydrationRecord::class, recordIdsList = it, clientRecordIdsList = emptyList())
        }
        return mapOf("inserted" to toInsert.size, "deleted" to toDelete.size)
    }

    private suspend fun readOwnRecords(start: Instant, end: Instant): List<HydrationRecord> {
        val records = mutableListOf<HydrationRecord>()
        var pageToken: String? = null
        do {
            val response = client.readRecords(
                ReadRecordsRequest(
                    recordType = HydrationRecord::class,
                    timeRangeFilter = TimeRangeFilter.between(start, end),
                    dataOriginFilter = setOf(DataOrigin(activity.packageName)),
                    pageToken = pageToken,
                ),
            )
            records += response.records
            pageToken = response.pageToken
        } while (pageToken != null)
        return records
    }

    private fun Map<String, Any>.toRecord(prefix: String): HydrationRecord {
        val time = Instant.ofEpochMilli((getValue("timeMs") as Number).toLong())
        val offset = ZoneOffset.ofTotalSeconds((getValue("offsetSeconds") as Number).toInt())
        return HydrationRecord(
            startTime = time,
            startZoneOffset = offset,
            endTime = time.plus(DRINK_DURATION),
            endZoneOffset = offset,
            volume = Volume.milliliters((getValue("ml") as Number).toDouble()),
            metadata = Metadata.manualEntry(clientRecordId = prefix + getValue("id") as String),
        )
    }

    private fun MethodCall.requireLong(key: String): Long =
        (argument<Number>(key) ?: throw IllegalArgumentException("Missing $key")).toLong()

    /** Opens the Play Store listing so the user can install or update Health Connect. */
    private fun openInstallPage(): Boolean {
        val market = Intent(
            Intent.ACTION_VIEW,
            Uri.parse("market://details?id=$PROVIDER_PACKAGE&url=healthconnect%3A%2F%2Fonboarding"),
        ).setPackage("com.android.vending")
            .putExtra("overlay", true)
            .putExtra("callerId", activity.packageName)
        val web = Intent(
            Intent.ACTION_VIEW,
            Uri.parse("https://play.google.com/store/apps/details?id=$PROVIDER_PACKAGE"),
        )
        return tryStart(market) || tryStart(web)
    }

    private fun openSettings(): Boolean =
        tryStart(Intent(HealthConnectClient.ACTION_HEALTH_CONNECT_SETTINGS))

    private fun tryStart(intent: Intent): Boolean = try {
        activity.startActivity(intent)
        true
    } catch (e: ActivityNotFoundException) {
        false
    }
}

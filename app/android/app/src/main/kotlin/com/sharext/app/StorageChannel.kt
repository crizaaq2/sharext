package com.sharext.app

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.provider.DocumentsContract
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * The one folder ShAre XT keeps files in.
 *
 * The owner picks it once with the system folder picker. The grant is
 * persistable, so the app keeps read and write access across restarts without
 * holding any storage permission.
 *
 * SAF is deliberate: on Android 10 and newer a plain storage permission only
 * reaches photos, video and audio. Files the owner drops into the folder with a
 * file manager are not media, so without the picker the app could not list them.
 */
class StorageChannel(private val activity: Activity) : MethodChannel.MethodCallHandler {

    companion object {
        const val CHANNEL = "sharext/storage"
        private const val PREFS = "sharext_storage"
        private const val KEY_URI = "folder_uri"
        private const val KEY_NAME = "folder_name"
        private const val PICK_FOLDER = 4110
        private const val GRANT_FLAGS =
            Intent.FLAG_GRANT_READ_URI_PERMISSION or Intent.FLAG_GRANT_WRITE_URI_PERMISSION
    }

    private val prefs = activity.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
    private var pending: MethodChannel.Result? = null

    fun attach(engine: FlutterEngine) {
        MethodChannel(engine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "folder" -> result.success(folderMap())
            "pickFolder" -> pickFolder(result)
            "list" -> result.success(listFiles())
            "forgetFolder" -> {
                forgetFolder()
                result.success(null)
            }
            else -> result.notImplemented()
        }
    }

    /** Returns true when this result belongs to the folder picker. */
    fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
        if (requestCode != PICK_FOLDER) return false
        val result = pending
        pending = null
        val uri: Uri? = data?.data
        if (resultCode != Activity.RESULT_OK || uri == null) {
            // Backing out of the picker is not an error: nothing changes.
            result?.success(null)
            return true
        }
        try {
            activity.contentResolver.takePersistableUriPermission(uri, GRANT_FLAGS)
        } catch (e: SecurityException) {
            result?.error("no_grant", "The system did not keep access to this folder.", null)
            return true
        }
        prefs.edit()
            .putString(KEY_URI, uri.toString())
            .putString(KEY_NAME, folderName(uri))
            .apply()
        result?.success(folderMap())
        return true
    }

    private fun pickFolder(result: MethodChannel.Result) {
        if (pending != null) {
            result.error("busy", "The folder picker is already open.", null)
            return
        }
        pending = result
        val intent = Intent(Intent.ACTION_OPEN_DOCUMENT_TREE).apply {
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
            addFlags(Intent.FLAG_GRANT_WRITE_URI_PERMISSION)
            addFlags(Intent.FLAG_GRANT_PERSISTABLE_URI_PERMISSION)
            addFlags(Intent.FLAG_GRANT_PREFIX_URI_PERMISSION)
        }
        try {
            activity.startActivityForResult(intent, PICK_FOLDER)
        } catch (e: Exception) {
            pending = null
            result.error("no_picker", "This device has no folder picker.", null)
        }
    }

    private fun forgetFolder() {
        val uri = prefs.getString(KEY_URI, null)
        prefs.edit().clear().apply()
        if (uri != null) {
            try {
                activity.contentResolver.releasePersistableUriPermission(Uri.parse(uri), GRANT_FLAGS)
            } catch (e: SecurityException) {
                // Already released; the stored value is gone, which is what matters.
            }
        }
    }

    private fun folderMap(): Map<String, Any?>? {
        val uri = prefs.getString(KEY_URI, null) ?: return null
        if (!hasGrant(uri)) {
            // The grant was revoked in system settings: report the truth.
            forgetFolder()
            return null
        }
        val name = prefs.getString(KEY_NAME, null) ?: folderName(Uri.parse(uri))
        return mapOf("uri" to uri, "name" to name)
    }

    private fun hasGrant(uri: String): Boolean =
        activity.contentResolver.persistedUriPermissions.any { it.uri.toString() == uri }

    private fun folderName(tree: Uri): String {
        val docId = try {
            DocumentsContract.getTreeDocumentId(tree)
        } catch (e: IllegalArgumentException) {
            return tree.lastPathSegment ?: "ShAre XT"
        }
        val name = queryName(DocumentsContract.buildDocumentUriUsingTree(tree, docId))
        return name ?: tree.lastPathSegment ?: "ShAre XT"
    }

    private fun queryName(docUri: Uri): String? = try {
        activity.contentResolver
            .query(docUri, arrayOf(DocumentsContract.Document.COLUMN_DISPLAY_NAME), null, null, null)
            ?.use { cursor -> if (cursor.moveToFirst()) cursor.getString(0) else null }
    } catch (e: Exception) {
        null
    }

    private fun listFiles(): List<Map<String, Any?>> {
        val uri = prefs.getString(KEY_URI, null) ?: return emptyList()
        if (!hasGrant(uri)) return emptyList()
        val tree = Uri.parse(uri)
        val children = try {
            DocumentsContract.buildChildDocumentsUriUsingTree(
                tree,
                DocumentsContract.getTreeDocumentId(tree),
            )
        } catch (e: IllegalArgumentException) {
            return emptyList()
        }
        val projection = arrayOf(
            DocumentsContract.Document.COLUMN_DISPLAY_NAME,
            DocumentsContract.Document.COLUMN_MIME_TYPE,
            DocumentsContract.Document.COLUMN_SIZE,
            DocumentsContract.Document.COLUMN_LAST_MODIFIED,
        )
        val out = mutableListOf<Map<String, Any?>>()
        try {
            activity.contentResolver.query(children, projection, null, null, null)?.use { cursor ->
                while (cursor.moveToNext()) {
                    val name = cursor.getString(0) ?: continue
                    out.add(
                        mapOf(
                            "name" to name,
                            "isFolder" to (DocumentsContract.Document.MIME_TYPE_DIR == cursor.getString(1)),
                            "bytes" to if (cursor.isNull(2)) -1L else cursor.getLong(2),
                            "modifiedAt" to if (cursor.isNull(3)) 0L else cursor.getLong(3),
                        ),
                    )
                }
            }
        } catch (e: Exception) {
            return emptyList()
        }
        return out
    }
}

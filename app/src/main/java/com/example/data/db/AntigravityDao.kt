package com.example.data.db

import androidx.room.Dao
import androidx.room.Delete
import androidx.room.Insert
import androidx.room.OnConflictStrategy
import androidx.room.Query
import androidx.room.Transaction
import androidx.room.Update
import com.example.data.entity.CodeProjectEntity
import com.example.data.entity.ExecutionRecordEntity
import com.example.data.entity.ProjectFileEntity
import com.example.data.entity.ProjectWithFiles
import com.example.data.entity.TerminalLogEntity
import kotlinx.coroutines.flow.Flow

@Dao
interface AntigravityDao {
    // Projects
    @Query("SELECT * FROM projects ORDER BY updatedAt DESC")
    fun getAllProjects(): Flow<List<CodeProjectEntity>>

    @Transaction
    @Query("SELECT * FROM projects ORDER BY updatedAt DESC")
    fun getProjectsWithFiles(): Flow<List<ProjectWithFiles>>

    @Transaction
    @Query("SELECT * FROM projects WHERE id = :id LIMIT 1")
    fun getProjectWithFilesFlow(id: Long): Flow<ProjectWithFiles?>

    @Transaction
    @Query("SELECT * FROM projects WHERE id = :id LIMIT 1")
    suspend fun getProjectWithFilesById(id: Long): ProjectWithFiles?

    @Query("SELECT * FROM projects WHERE id = :id LIMIT 1")
    suspend fun getProjectById(id: Long): CodeProjectEntity?

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertProject(project: CodeProjectEntity): Long

    @Update
    suspend fun updateProject(project: CodeProjectEntity)

    @Delete
    suspend fun deleteProject(project: CodeProjectEntity)

    @Query("DELETE FROM projects WHERE id = :projectId")
    suspend fun deleteProjectById(projectId: Long)

    @Query("UPDATE projects SET activeFileId = :fileId, updatedAt = :updatedAt WHERE id = :projectId")
    suspend fun updateActiveFile(projectId: Long, fileId: Long, updatedAt: Long = System.currentTimeMillis())

    @Query("UPDATE projects SET compilerFlags = :flags, runtimeTarget = :target, environmentVariables = :env, updatedAt = :updatedAt WHERE id = :projectId")
    suspend fun updateProjectLanguageConfig(
        projectId: Long,
        flags: String,
        target: String,
        env: String,
        updatedAt: Long = System.currentTimeMillis()
    )

    @Query("UPDATE projects SET workspaceOwnership = :ownership, debianWorkspaceSlug = :slug, lastSyncedAtMs = :syncedAtMs, updatedAt = :updatedAt WHERE id = :projectId")
    suspend fun updateProjectWorkspaceSync(
        projectId: Long,
        ownership: String,
        slug: String,
        syncedAtMs: Long,
        updatedAt: Long = System.currentTimeMillis()
    )

    @Query("SELECT * FROM projects ORDER BY updatedAt DESC")
    suspend fun getAllProjectsSnapshot(): List<CodeProjectEntity>

    // Files & Structure
    @Query("SELECT * FROM project_files WHERE projectId = :projectId ORDER BY directoryPath ASC, fileName ASC")
    fun getFilesForProject(projectId: Long): Flow<List<ProjectFileEntity>>

    @Query("SELECT * FROM project_files WHERE projectId = :projectId ORDER BY directoryPath ASC, fileName ASC")
    suspend fun getFilesForProjectSnapshot(projectId: Long): List<ProjectFileEntity>

    @Query("SELECT * FROM project_files WHERE id = :fileId LIMIT 1")
    suspend fun getFileById(fileId: Long): ProjectFileEntity?

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertFile(file: ProjectFileEntity): Long

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertFiles(files: List<ProjectFileEntity>): List<Long>

    @Update
    suspend fun updateFile(file: ProjectFileEntity)

    @Query("UPDATE project_files SET contentSha256 = :sha256, syncState = :syncState WHERE id = :fileId")
    suspend fun updateFileSyncMetadata(fileId: Long, sha256: String, syncState: String)

    @Query("UPDATE project_files SET contentSha256 = :sha256, lastSyncedSha256 = :lastSyncedSha256, syncState = :syncState WHERE id = :fileId")
    suspend fun updateFileSyncResult(fileId: Long, sha256: String, lastSyncedSha256: String, syncState: String)

    @Delete
    suspend fun deleteFile(file: ProjectFileEntity)

    @Query("DELETE FROM project_files WHERE id = :fileId")
    suspend fun deleteFileById(fileId: Long)

    // Terminal History
    @Query("SELECT * FROM terminal_history ORDER BY timestamp DESC LIMIT 50")
    fun getTerminalLogs(): Flow<List<TerminalLogEntity>>

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertTerminalLog(log: TerminalLogEntity): Long

    @Query("DELETE FROM terminal_history")
    suspend fun clearTerminalLogs()

    // Execution Records
    @Query("SELECT * FROM execution_records ORDER BY timestamp DESC LIMIT 20")
    fun getExecutionRecords(): Flow<List<ExecutionRecordEntity>>

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertExecutionRecord(record: ExecutionRecordEntity): Long
}

export class ConflictResolver {
    resolve(local: any, remote: any) {
        // Simple Last-Write-Wins or customized logic
        // Return the version that should persist
        if (new Date(local.updated_at) > new Date(remote.updated_at)) {
            return local;
        }
        return remote;
    }
}

export const conflictResolver = new ConflictResolver();

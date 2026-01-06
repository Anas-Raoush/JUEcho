// amplify/storage/resource.ts
import { defineStorage } from '@aws-amplify/backend';

export const storage = defineStorage({
  name: 'feedbackImageStorage',
  access: (allow) => ({
    // All feedback images are stored under:
    // incoming/{entity_id}/...
    //
    // - The owner (identity) can read/write/delete their own files
    // - Admins can read/delete ANY student's files
    'incoming/{entity_id}/*': [
      allow.entity('identity').to(['read', 'write', 'delete']),
      allow.groups(['admin']).to(['read', 'delete']),
    ],
  }),
});
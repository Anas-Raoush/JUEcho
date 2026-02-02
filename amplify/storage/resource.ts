import { defineStorage } from "@aws-amplify/backend";

/**
 * S3 storage configuration for feedback image attachments.
 *
 * Storage layout
 * - All images are stored under:
 *   incoming/{entity_id}/...
 *
 * Access control
 * - identity owner:
 *   - can read/write/delete their own objects under their entity_id namespace
 * - admin group:
 *   - can read/delete any student's objects for moderation and support
 *
 * Notes
 * - entity('identity') maps to the current authenticated identity.
 * - This file defines API-level access control; application-level policies
 *   (example: when to allow uploads) should be enforced in the client logic.
 */
export const storage = defineStorage({
  name: 'feedbackImageStorage',
  access: (allow) => ({
    'incoming/{entity_id}/*': [
      allow.entity('identity').to(['read', 'write', 'delete']),
      allow.groups(['admin']).to(['read', 'delete']),
    ],
  }),
});
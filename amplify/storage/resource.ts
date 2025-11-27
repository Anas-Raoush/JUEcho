import { defineStorage } from '@aws-amplify/backend';

export const storage = defineStorage({
  // Friendly name – will appear in amplify_outputs
  name: 'feedbackImageStorage',

  // Access rules for S3 paths
  access: (allow) => ({
    // All feedback images go under the "incoming/" prefix
    // Only authenticated users (signed in) can read/write/delete
    'incoming/*': [
      allow.authenticated.to(['read', 'write', 'delete']),
    ],
  }),
});

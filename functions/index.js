/* eslint-disable indent */
const functions = require("firebase-functions");
const admin = require("firebase-admin");
admin.initializeApp();

// // Create and Deploy Your First Cloud Functions
// // https://firebase.google.com/docs/functions/write-firebase-functions
//

exports.addChatMessage = functions.firestore
    .document("/chats/{chatsId}/messages/{messageId}")
    .onCreate(async (snapshot, context) => {
        const chatId = context.params.chatId;
        const messageData = snapshot.data();
        const chatRef = admin.firestore()
            .collectionGroup("chats").document(chatId);
        const chatDoc = await chatRef.get();
        const chatData = chatDoc.data();
        if (chatDoc.exists) {
            const readStatus = chatData.readStatus;
            for (const userId in readStatus) {
                // eslint-disable-next-line no-prototype-builtins
                if (readStatus.hasOwnProperty(userId) &&
                    userId !== messageData.senderId) {
                    readStatus[userId] = false;
                }
            }
            chatRef.update({
                recentMessage: messageData.text,
                recentSender: messageData.senderId,
                recentTimestamp: messageData.timestamp,
                readStatus: readStatus,
            });
        }
    });


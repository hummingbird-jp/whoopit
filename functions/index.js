const functions = require("firebase-functions");
const admin = require("firebase-admin");
const {RtcRole, RtcTokenBuilder} = require("agora-access-token");
admin.initializeApp();

exports.fetchTokenWithUid = functions.https.onCall(
    (data, context) => {
      const appID = "8d98fb1cbd094508bff710b6a2d199ef";
      const appCertificate = "dc369a70ad7543f8bee97b822f6d3372";
      const channelName = data.channelName;
      const agoraUid = data.agoraUid;
      const role = RtcRole.PUBLISHER;
      const expirationTimeInSeconds = 3600;
      const currentTimestamp = Math.floor(Date.now() / 1000);
      const privilegeExpiredTs = currentTimestamp + expirationTimeInSeconds;

      functions.logger.debug(`appID: ${appID}`);
      functions.logger.debug(`appCertificate: ${appCertificate}`);
      functions.logger.debug(`channelName: ${channelName}`);
      functions.logger.debug(`agoraUid: ${agoraUid}`);
      functions.logger.debug(`currentTimestamp: ${currentTimestamp}`);
      functions.logger.debug(`privilegeExpiredTs: ${privilegeExpiredTs}`);

      try {
        const token = RtcTokenBuilder.buildTokenWithUid(
            appID,
            appCertificate,
            channelName,
            agoraUid,
            role,
            privilegeExpiredTs
        );
        functions.logger.debug(`Token Generated with Agora UID: ${token}`);
        return token;
      } catch (error) {
        functions.logger.error(`Error generating token: ${error}`);
        if (!(typeof channelName === "string") || channelName.length === 0) {
          throw new functions.https.HttpsError(
              "invalid-argument",
              "The function must be called with " +
            "one arguments \"text\" containing the message text to add."
          );
        }
        if (!context.auth) {
          throw new functions.https.HttpsError(
              "failed-precondition",
              "The function must be called " + "while authenticated."
          );
        }
      }
    });

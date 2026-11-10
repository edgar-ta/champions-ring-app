/**
 * Import function triggers from their respective submodules:
 *
 * const {onCall} = require("firebase-functions/v2/https");
 * const {onDocumentWritten} = require("firebase-functions/v2/firestore");
 *
 * See a full list of supported triggers at https://firebase.google.com/docs/functions
 */

const { setGlobalOptions } = require("firebase-functions");
const { onDocumentCreated } = require("firebase-functions/firestore");

// The Firebase Admin SDK to access Firestore.
const { initializeApp } = require("firebase-admin/app");
const { Timestamp } = require("firebase-admin/firestore");
const { calculateRenewalEndDate } = require("./renewal_date");

initializeApp();

// For cost control, you can set the maximum number of containers that can be
// running at the same time. This helps mitigate the impact of unexpected
// traffic spikes by instead downgrading performance. This limit is a
// per-function limit. You can override the limit for each function using the
// `maxInstances` option in the function's options, e.g.
// `onRequest({ maxInstances: 5 }, (req, res) => { ... })`.
// NOTE: setGlobalOptions does not apply to functions using the v1 API. V1
// functions should each use functions.runWith({ maxInstances: 10 }) instead.
// In the v1 API, each function can only serve one request per container, so
// this will be the maximum concurrent request count.
setGlobalOptions({ maxInstances: 10 });

// Create and deploy your first functions
// https://firebase.google.com/docs/functions/get-started

exports.addRenewalEndDate = onDocumentCreated(
  "/members/{memberId}/renewals/{renewalId}",
  async (event) => {
    const renewalSnapshot = event.data;
    if (!renewalSnapshot) {
      throw new Error("The created renewal document is missing.");
    }

    const renewal = renewalSnapshot.data();
    const membershipPlanRef = renewal.membershipPlanRef;
    if (!membershipPlanRef) {
      throw new Error("The renewal has no membership plan reference.");
    }

    const membershipPlanSnapshot = await membershipPlanRef.get();
    if (!membershipPlanSnapshot.exists) {
      throw new Error(
        `Membership plan "${membershipPlanRef.path}" was not found.`,
      );
    }

    const startDate = renewal.startDate;
    if (!startDate || typeof startDate.toMillis !== "function") {
      throw new TypeError(
        "The renewal start date must be a Firestore timestamp.",
      );
    }

    const endDateMillis = calculateRenewalEndDate(
      startDate.toMillis(),
      membershipPlanSnapshot.get("duration"),
    );

    return renewalSnapshot.ref.update({
      endDate: Timestamp.fromMillis(endDateMillis),
    });
  },
);

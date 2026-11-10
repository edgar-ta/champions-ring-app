const millisecondsPerDay = 24 * 60 * 60 * 1000;

/**
 * Calculates the end timestamp from a renewal start and plan duration.
 * @param {number} startDateMillis Start timestamp in milliseconds.
 * @param {string} duration Membership plan duration serialization.
 * @return {number} End timestamp in milliseconds.
 */
function calculateRenewalEndDate(startDateMillis, duration) {
  if (!Number.isFinite(startDateMillis)) {
    throw new TypeError("The renewal start date must be a valid timestamp.");
  }

  let durationInDays;
  switch (duration) {
    case "1d":
      durationInDays = 1;
      break;
    case "1w":
      durationInDays = 7;
      break;
    case "1m":
      durationInDays = 30;
      break;
    default:
      throw new RangeError(`Unknown membership plan duration "${duration}".`);
  }

  return startDateMillis + durationInDays * millisecondsPerDay;
}

module.exports = {calculateRenewalEndDate};

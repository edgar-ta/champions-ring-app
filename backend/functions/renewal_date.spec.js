const assert = require("node:assert/strict");
const {test} = require("node:test");
const {calculateRenewalEndDate} = require("./renewal_date");

const startDateMillis = Date.UTC(2026, 0, 15, 12);
const millisecondsPerDay = 24 * 60 * 60 * 1000;

test("adds one day for a one-day plan", () => {
  assert.equal(
      calculateRenewalEndDate(startDateMillis, "1d"),
      startDateMillis + millisecondsPerDay,
  );
});

test("adds seven days for a one-week plan", () => {
  assert.equal(
      calculateRenewalEndDate(startDateMillis, "1w"),
      startDateMillis + 7 * millisecondsPerDay,
  );
});

test("adds thirty days for a one-month plan", () => {
  assert.equal(
      calculateRenewalEndDate(startDateMillis, "1m"),
      startDateMillis + 30 * millisecondsPerDay,
  );
});

test("rejects unknown plan durations", () => {
  assert.throws(
      () => calculateRenewalEndDate(startDateMillis, "2m"),
      /Unknown membership plan duration/,
  );
});

test("rejects invalid start timestamps", () => {
  assert.throws(
      () => calculateRenewalEndDate(Number.NaN, "1d"),
      /start date must be a valid timestamp/,
  );
});

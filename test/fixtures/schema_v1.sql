CREATE TABLE saving_records (
 id INTEGER PRIMARY KEY AUTOINCREMENT,
 kind TEXT NOT NULL CHECK(kind IN ('budget','alternative','forgone')),
 description TEXT NOT NULL CHECK(length(trim(description)) BETWEEN 1 AND 200),
 baseline_minor INTEGER, actual_minor INTEGER,
 saved_minor INTEGER NOT NULL CHECK(saved_minor >= 0),
 currency_code TEXT NOT NULL CHECK(currency_code = 'CNY'),
 occurred_on TEXT NOT NULL, created_at_utc TEXT NOT NULL, updated_at_utc TEXT NOT NULL,
 CHECK ((kind = 'forgone' AND baseline_minor IS NULL AND actual_minor IS NULL AND saved_minor = 0)
 OR (kind IN ('budget','alternative') AND baseline_minor IS NOT NULL AND actual_minor IS NOT NULL
 AND baseline_minor BETWEEN 1 AND 999999999 AND actual_minor BETWEEN 0 AND 999999999
 AND baseline_minor > actual_minor AND saved_minor = baseline_minor - actual_minor))
)

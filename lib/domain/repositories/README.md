# Reactive repository contracts

`CategoryStore`, `TodoStore`, `ChatStore`, `MemoryStore`, `ReportStore`,
`DataTableStore` and `QuotaStore` are the boundary consumed by application
providers and view models. They retain Riverpod's existing notifier contract;
no replacement state-management framework or remote protocol is required.

- Application composition lives in `lib/app/providers.dart`. Override a store
  provider to inject a different implementation. Concrete in-memory repositories
  live in `lib/data/repositories/`; fixtures live separately in `lib/data/seeds/`.
- `ListStore.snapshot` and `DataTableBundle` expose defensive, unmodifiable
  collection snapshots. Domain models freeze their nested collections. Commands
  publish replacement snapshots so old readers cannot mutate repository state.
- In-memory repositories accept initial snapshots; time-dependent repositories
  accept a clock. `ReportRepository` also accepts generation delay and completion
  function so concurrency, cancellation and failures can be tested deterministically.
- Report generation owns one timer per report. Disposal cancels all work; stopping
  a report affects only its generating item. Generation failures publish a failed
  state with a retryable message.
- `RepositoryException` distinguishes invalid input, missing data and conflicts.
  UI commands should display its message rather than silently discard errors.
  AI batch application stages all selected writes and commits once; stale values
  or cross-table references reject the whole command. Unselected changes remain
  pending. Undo checks for later row edits and appends compensating audit logs.
- Data-table writes validate the complete resulting row, including required
  cells, exact schema field identifiers, finite numbers/money, calendar-valid
  `yyyy-MM-dd` dates, `yyyy-MM-dd HH:mm` or ISO date-times, declared selections,
  and `true`/`false` booleans. Optional cells clear with `''`; input is never
  silently normalized. Initial rows, template seeds and raw undo insertion use
  the same boundary. AI proposals may remain pending with invalid values; their
  application rejects atomically before publishing any rows or audit logs.
- Data-table UI catches only `RepositoryException`. Failed submissions preserve
  entered values and AI selections; successful writes close their editor. Other
  exceptions propagate so programming errors are not disguised as validation.

This is still an in-memory demonstration. Persistence, server reconciliation,
and cross-repository coordination are separate concerns. These contracts do not
define a backend or database schema.

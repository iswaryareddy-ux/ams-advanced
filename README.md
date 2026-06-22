# Asset Management System (AMS)

A web-based Asset Management System for tracking organizational assets
(computers, laptops, printers, servers, networking gear, furniture, AC
units, software licenses, projectors and vehicles) through their full
lifecycle &mdash; registration, allocation, maintenance, and disposal.

**Stack**
- Frontend: HTML, CSS, vanilla JavaScript
- Backend: JSP (JavaServer Pages) with JDBC, run on Apache Tomcat
- Database: MySQL (default) or Oracle (see notes below)

---

## 1. Features

- Role-based login (Admin / User)
- Asset registry with category, serial number, purchase details, vendor,
  warranty, location and status
- QR code generation per asset (for printing onto physical tags)
- Employee-wise asset allocation (issue / return tracking with history)
- Vendor directory linked to assets and maintenance records
- Maintenance ticketing &mdash; logging a ticket sets the asset to
  "Under Repair"; marking it complete returns the asset to service
- Dashboard with live counts (total, in use, available, under repair,
  warranty expiring soon), category breakdown and recent activity
- Reports: Available assets, Assigned assets, Faulty/Under repair assets,
  Depreciation (straight-line, per-category rate), and Audit trail
- Audit log of logins, creates, updates, deletes, issues and returns
- Backup & restore via standard `mysqldump` / `mysql` (see section 6)

---

## 2. Project structure

```
AMS/
├── css/style.css            Shared stylesheet (design system)
├── js/script.js              Shared front-end behaviour (search, filters,
│                              modals, QR rendering, confirmations)
├── includes/
│   ├── header.jsp             Page <head>, auth guard, topbar
│   ├── sidebar.jsp            Left navigation
│   └── footer.jsp             Closing markup + script includes
├── WEB-INF/
│   ├── web.xml                 Deployment descriptor
│   └── classes/
│       ├── db.properties       Database connection settings
│       └── com/ams/util/DBConnection.java
├── database/
│   └── ams_schema.sql          Full schema + seed data (MySQL)
├── index.jsp                  Login page
├── login_action.jsp           Authenticates against the `users` table
├── logout.jsp                 Ends the session
├── dashboard.jsp              Stats, category breakdown, recent activity
├── assets.jsp                 Asset registry (list, search, filter)
├── asset_form.jsp             Add / edit / issue asset
├── asset_action.jsp           Create / update / delete / issue / return
├── employees.jsp              Employee directory
├── employee_form.jsp          Add / edit employee
├── employee_action.jsp        Create / update / delete employee
├── vendors.jsp                Vendor directory
├── vendor_form.jsp            Add / edit vendor
├── vendor_action.jsp          Create / update / delete vendor
├── maintenance.jsp            Maintenance ticket list
├── maintenance_form.jsp       Add / edit maintenance ticket
├── maintenance_action.jsp     Create / update / complete / delete ticket
├── reports.jsp                Report viewer (5 report types)
└── error.jsp                  Friendly error page (404 / 500)
```

---

## 3. Database setup

1. Install MySQL 8 (or MariaDB) and create a dedicated user:

   ```sql
   CREATE USER 'ams_user'@'localhost' IDENTIFIED BY 'ams_password';
   GRANT ALL PRIVILEGES ON ams_db.* TO 'ams_user'@'localhost';
   FLUSH PRIVILEGES;
   ```

2. Import the schema and seed data:

   ```bash
   mysql -u ams_user -p < database/ams_schema.sql
   ```

   This creates the `ams_db` database, all tables, and sample data
   (10 sample assets, 6 employees, 5 vendors, maintenance history, and
   two login accounts):

   | Username | Password   | Role  |
   |-----------|------------|-------|
   | admin     | admin123   | Admin |
   | kverma    | user123    | User  |

   **Change these credentials before using this in production**, and
   store hashed passwords (e.g. BCrypt) instead of plain text &mdash;
   the schema's `password` column simply needs to be wide enough
   (`VARCHAR(255)`) to hold a hash.

### Using Oracle instead of MySQL

`database/ams_schema.sql` is written for MySQL syntax (`AUTO_INCREMENT`,
`ENUM`, `DATETIME`). For Oracle:

- Replace `AUTO_INCREMENT` columns with `GENERATED ALWAYS AS IDENTITY`
  (Oracle 12c+) or a sequence + trigger on older versions.
- Replace `ENUM(...)` columns with `VARCHAR2(20)` plus a `CHECK` constraint.
- Replace `DATETIME` with `TIMESTAMP` and `CURDATE()` with `TRUNC(SYSDATE)`.
- Update `WEB-INF/classes/db.properties` to use the Oracle JDBC driver
  and connection string (a commented-out example is included in that file).

---

## 4. Application server setup (Apache Tomcat)

1. Install a JDK (11+) and Apache Tomcat 10 (Servlet 5.0 / Jakarta EE,
   matches the `web.xml` in this project). For Tomcat 9, see the note
   at the bottom of `WEB-INF/web.xml` to switch to the Servlet 4.0
   descriptor and the `javax.*` namespace instead of `jakarta.*`.

2. Download the JDBC driver jar and place it in Tomcat's shared
   library folder (`<TOMCAT_HOME>/lib/`):
   - MySQL: `mysql-connector-j-<version>.jar`
   - Oracle: `ojdbc11.jar`

3. Edit `WEB-INF/classes/db.properties` with your database host,
   credentials, and (if using Oracle) uncomment the Oracle block and
   comment out the MySQL block.

4. Deploy the project:
   - Copy the entire `AMS/` folder into
     `<TOMCAT_HOME>/webapps/AMS/` (the folder name becomes the context
     path).
   - Start Tomcat: `<TOMCAT_HOME>/bin/startup.sh` (or `startup.bat` on
     Windows).
   - Visit `http://localhost:8080/AMS/`.

---

## 5. How the pieces fit together

- **Authentication**: `index.jsp` posts to `login_action.jsp`, which
  checks `username` + `password` + `role` against the `users` table
  and stores `username`, `fullName`, `role`, `employeeId` in the
  session. Every protected page includes `includes/header.jsp`, which
  redirects to `index.jsp` if there's no session.
- **CRUD pattern**: each module follows list page → form page → action
  page, e.g. `assets.jsp` → `asset_form.jsp` → `asset_action.jsp`.
  Action pages use `PreparedStatement` for all queries, write a row to
  `audit_log`, then redirect back to the list page with a `flash`
  query parameter that the list page turns into a success banner.
- **Issue / Return**: issuing an asset (`asset_action.jsp?op=issue`)
  sets `assets.status='In Use'`, `assets.assigned_to=<employee>`, and
  inserts a row into `asset_allocations`. Returning closes that
  allocation row and clears the assignment.
- **Maintenance**: logging a ticket sets the asset to `Under Repair`.
  Marking it "Completed" (via the checkmark button or the edit form)
  returns the asset to `In Use` (if still assigned) or `Available`.
- **QR codes**: `js/script.js` renders a QR code client-side (via
  `qrcode.js` from cdnjs) encoding `ASSET:<asset_id>`. Point a barcode
  scanner app at `assets.jsp?action=view&id=<asset_id>` if you wire up
  a dedicated lookup endpoint.
- **Reports & Depreciation**: `reports.jsp` computes straight-line
  depreciation in Java using each category's `depreciation_rate` from
  `asset_categories` and the asset's age in years.

---

## 6. Backup & restore

```bash
# Backup
mysqldump -u ams_user -p ams_db > ams_db_backup.sql

# Restore
mysql -u ams_user -p ams_db < ams_db_backup.sql
```

---

## 7. Suggested next steps

- Hash passwords (BCrypt) instead of storing them in plain text.
- Add server-side validation and CSRF tokens to all forms.
- Add pagination for large asset lists (the current search/filter is
  client-side and works well up to a few hundred rows).
- Wire up email notifications (e.g. via `JavaMail`) for warranty
  expiry and maintenance status changes.
- Add a barcode/QR scanning page using the device camera
  (e.g. `html5-qrcode`) for fast check-in/check-out.

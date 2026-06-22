-- ============================================================
-- Asset Management System (AMS) - Database Schema
-- Target: MySQL 8 (also compatible with MariaDB)
--
-- For Oracle, replace AUTO_INCREMENT with a sequence + trigger
-- (or GENERATED ALWAYS AS IDENTITY on 12c+), ENUM columns with
-- VARCHAR2 + CHECK constraints, and DATETIME with TIMESTAMP.
-- ============================================================

CREATE DATABASE IF NOT EXISTS ams_db
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

USE ams_db;

-- ------------------------------------------------------------
-- Reference data
-- ------------------------------------------------------------

CREATE TABLE asset_categories (
    category_id     INT AUTO_INCREMENT PRIMARY KEY,
    category_name   VARCHAR(60)  NOT NULL UNIQUE,
    depreciation_rate DECIMAL(5,2) NOT NULL DEFAULT 10.00 -- percent per year, straight-line
);

CREATE TABLE vendors (
    vendor_id       INT AUTO_INCREMENT PRIMARY KEY,
    vendor_name     VARCHAR(120) NOT NULL,
    contact_person  VARCHAR(80),
    phone           VARCHAR(20),
    email           VARCHAR(100),
    address         VARCHAR(200),
    created_at      DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- ------------------------------------------------------------
-- People
-- ------------------------------------------------------------

CREATE TABLE employees (
    employee_id     INT AUTO_INCREMENT PRIMARY KEY,
    name            VARCHAR(100) NOT NULL,
    department      VARCHAR(60),
    designation     VARCHAR(60),
    phone           VARCHAR(20),
    email           VARCHAR(100),
    status          ENUM('Active','Inactive') NOT NULL DEFAULT 'Active',
    created_at      DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- System login accounts (role-based access)
CREATE TABLE users (
    user_id         INT AUTO_INCREMENT PRIMARY KEY,
    username        VARCHAR(50)  NOT NULL UNIQUE,
    password        VARCHAR(255) NOT NULL,         -- store a hashed value in production
    full_name       VARCHAR(100) NOT NULL,
    role            ENUM('Admin','User') NOT NULL DEFAULT 'User',
    employee_id     INT NULL,
    status          ENUM('Active','Inactive') NOT NULL DEFAULT 'Active',
    last_login      DATETIME NULL,
    created_at      DATETIME DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_users_employee FOREIGN KEY (employee_id) REFERENCES employees(employee_id)
        ON DELETE SET NULL
);

-- ------------------------------------------------------------
-- Assets
-- ------------------------------------------------------------

CREATE TABLE assets (
    asset_id        VARCHAR(20) PRIMARY KEY,        -- e.g. AST-1001 (also encoded into QR/barcode)
    asset_name      VARCHAR(120) NOT NULL,
    category_id     INT NOT NULL,
    serial_no       VARCHAR(100) UNIQUE,
    purchase_date   DATE,
    purchase_cost   DECIMAL(12,2) DEFAULT 0,
    vendor_id       INT NULL,
    warranty_expiry DATE NULL,
    location        VARCHAR(100),
    status          ENUM('Available','In Use','Under Repair','Disposed') NOT NULL DEFAULT 'Available',
    assigned_to     INT NULL,                       -- employees.employee_id, NULL when not issued
    created_at      DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at      DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT fk_assets_category FOREIGN KEY (category_id) REFERENCES asset_categories(category_id),
    CONSTRAINT fk_assets_vendor   FOREIGN KEY (vendor_id)   REFERENCES vendors(vendor_id) ON DELETE SET NULL,
    CONSTRAINT fk_assets_employee FOREIGN KEY (assigned_to) REFERENCES employees(employee_id) ON DELETE SET NULL
);

-- Issue / return history (employee-wise allocation tracking)
CREATE TABLE asset_allocations (
    allocation_id   INT AUTO_INCREMENT PRIMARY KEY,
    asset_id        VARCHAR(20) NOT NULL,
    employee_id     INT NOT NULL,
    issue_date      DATE NOT NULL,
    return_date     DATE NULL,
    issued_by       VARCHAR(100),
    remarks         VARCHAR(255),
    CONSTRAINT fk_alloc_asset    FOREIGN KEY (asset_id) REFERENCES assets(asset_id) ON DELETE CASCADE,
    CONSTRAINT fk_alloc_employee FOREIGN KEY (employee_id) REFERENCES employees(employee_id)
);

-- Maintenance / service history
CREATE TABLE maintenance (
    maintenance_id  INT AUTO_INCREMENT PRIMARY KEY,
    asset_id        VARCHAR(20) NOT NULL,
    issue_reported  VARCHAR(255) NOT NULL,
    service_date    DATE NOT NULL,
    completed_date  DATE NULL,
    vendor_id       INT NULL,
    cost            DECIMAL(10,2) DEFAULT 0,
    status          ENUM('Open','In Progress','Completed') NOT NULL DEFAULT 'Open',
    remarks         VARCHAR(255),
    CONSTRAINT fk_maint_asset  FOREIGN KEY (asset_id) REFERENCES assets(asset_id) ON DELETE CASCADE,
    CONSTRAINT fk_maint_vendor FOREIGN KEY (vendor_id) REFERENCES vendors(vendor_id) ON DELETE SET NULL
);

-- Disposal history
CREATE TABLE asset_disposals (
    disposal_id     INT AUTO_INCREMENT PRIMARY KEY,
    asset_id        VARCHAR(20) NOT NULL,
    disposal_date   DATE NOT NULL,
    reason          VARCHAR(255),
    approved_by     VARCHAR(100),
    disposal_value  DECIMAL(10,2) DEFAULT 0,
    CONSTRAINT fk_disposal_asset FOREIGN KEY (asset_id) REFERENCES assets(asset_id) ON DELETE CASCADE
);

-- Audit trail (who did what, when)
CREATE TABLE audit_log (
    log_id          BIGINT AUTO_INCREMENT PRIMARY KEY,
    username        VARCHAR(50),
    action          VARCHAR(50)  NOT NULL,   -- e.g. CREATE, UPDATE, DELETE, ISSUE, RETURN, LOGIN
    entity          VARCHAR(50)  NOT NULL,   -- e.g. ASSET, EMPLOYEE, VENDOR, MAINTENANCE
    entity_id       VARCHAR(50),
    details         VARCHAR(500),
    created_at      DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- ------------------------------------------------------------
-- Useful indexes
-- ------------------------------------------------------------
CREATE INDEX idx_assets_status   ON assets(status);
CREATE INDEX idx_assets_category ON assets(category_id);
CREATE INDEX idx_alloc_asset     ON asset_allocations(asset_id);
CREATE INDEX idx_maint_asset     ON maintenance(asset_id);

-- ============================================================
-- Seed data
-- ============================================================

INSERT INTO asset_categories (category_name, depreciation_rate) VALUES
 ('Computers', 20.00),
 ('Laptops', 25.00),
 ('Printers', 15.00),
 ('Servers', 12.50),
 ('Routers/Switches', 15.00),
 ('Furniture', 5.00),
 ('Air Conditioners', 10.00),
 ('Software Licenses', 33.33),
 ('Projectors', 15.00),
 ('Vehicles', 10.00);

INSERT INTO vendors (vendor_name, contact_person, phone, email, address) VALUES
 ('Dell Technologies India',   'Rohit Sharma', '9810000001', 'sales@dell-partner.com',  'Plot 14, Okhla Industrial Area, New Delhi'),
 ('HP Authorized Reseller',    'Priya Nair',   '9810000002', 'support@hp-reseller.com', 'MG Road, Bengaluru'),
 ('Cisco Networking Solutions','Arjun Mehta',  '9810000003', 'arjun@cisconet.in',       'Cyber Towers, Hyderabad'),
 ('Godrej Interio',            'Sunita Rao',   '9810000004', 'orders@godrejinterio.com','Vikhroli, Mumbai'),
 ('Voltas Service Center',     'Imran Khan',   '9810000005', 'service@voltas.com',      'Sector 18, Gurugram');

INSERT INTO employees (name, department, designation, phone, email) VALUES
 ('Aarav Mehta',   'IT',          'System Administrator', '9876543210', 'aarav.mehta@company.com'),
 ('Diya Kapoor',   'HR',          'HR Executive',         '9876543211', 'diya.kapoor@company.com'),
 ('Rohan Iyer',    'Finance',     'Accountant',           '9876543212', 'rohan.iyer@company.com'),
 ('Sneha Reddy',   'Marketing',   'Marketing Manager',    '9876543213', 'sneha.reddy@company.com'),
 ('Karan Verma',   'Operations',  'Operations Lead',      '9876543214', 'karan.verma@company.com'),
 ('Megha Joshi',   'IT',          'Network Engineer',     '9876543215', 'megha.joshi@company.com');

-- Default login accounts
-- Username: admin  / Password: admin123   (Admin role)
-- Username: kverma / Password: user123    (User role, linked to an employee)
INSERT INTO users (username, password, full_name, role, employee_id, status) VALUES
 ('admin',  'admin123', 'System Administrator', 'Admin', 1, 'Active'),
 ('kverma', 'user123',  'Karan Verma',          'User',  5, 'Active');

INSERT INTO assets
 (asset_id, asset_name, category_id, serial_no, purchase_date, purchase_cost, vendor_id, warranty_expiry, location, status, assigned_to)
VALUES
 ('AST-1001', 'Dell Latitude 5440 Laptop', 2, 'DL5440-88231', '2024-02-15', 68500.00, 1, '2027-02-14', 'IT Department',     'In Use',     1),
 ('AST-1002', 'Dell Latitude 5440 Laptop', 2, 'DL5440-88232', '2024-02-15', 68500.00, 1, '2027-02-14', 'Marketing',         'In Use',     4),
 ('AST-1003', 'HP LaserJet Pro M404',      3, 'HP404-55102',  '2023-08-10', 21500.00, 2, '2025-08-09', 'Finance Department','Under Repair', 3),
 ('AST-1004', 'Cisco Catalyst 2960 Switch',5, 'CSC2960-9981', '2022-11-01', 45500.00, 3, '2025-10-31', 'Server Room',       'In Use',     1),
 ('AST-1005', 'Dell PowerEdge R740 Server',4, 'PE740-30221',  '2022-05-20', 410000.00, 1, '2027-05-19','Server Room',       'In Use',     1),
 ('AST-1006', 'Office Desk - Oak',         6, 'GDJ-DESK-1190','2021-01-12', 12500.00, 4, NULL,         'Operations',        'In Use',     5),
 ('AST-1007', 'Voltas 1.5T Split AC',      7, 'VOL15T-7741',  '2023-04-02', 38000.00, 5, '2025-04-01', 'HR Office',         'Available',  NULL),
 ('AST-1008', 'MS Office 365 License',     8, 'MSO365-AX991', '2024-01-01', 9600.00,  NULL, '2025-01-01','Software Pool',   'In Use',     2),
 ('AST-1009', 'Epson Projector EB-2055',   9, 'EPS2055-6620', '2023-09-18', 54000.00, 2, '2025-09-17', 'Conference Room A', 'Available',  NULL),
 ('AST-1010', 'Lenovo ThinkPad E14',       2, 'LNV14-30041',  '2021-06-30', 62000.00, 1, '2023-06-29', 'Store Room',        'Disposed',   NULL);

INSERT INTO asset_allocations (asset_id, employee_id, issue_date, return_date, issued_by, remarks) VALUES
 ('AST-1001', 1, '2024-02-20', NULL, 'admin', 'Initial issue to IT admin'),
 ('AST-1002', 4, '2024-02-22', NULL, 'admin', 'Issued to marketing team'),
 ('AST-1004', 1, '2022-11-05', NULL, 'admin', 'Network switch for server room'),
 ('AST-1005', 1, '2022-05-25', NULL, 'admin', 'Primary application server'),
 ('AST-1006', 5, '2021-01-15', NULL, 'admin', 'Workstation desk'),
 ('AST-1008', 2, '2024-01-05', NULL, 'admin', 'HR laptop license activation'),
 ('AST-1010', 3, '2021-07-01', '2023-06-30', 'admin', 'Returned before disposal');

INSERT INTO maintenance (asset_id, issue_reported, service_date, completed_date, vendor_id, cost, status, remarks) VALUES
 ('AST-1003', 'Paper jam and faded print quality', '2025-06-10', NULL, 2, 1500.00, 'In Progress', 'Awaiting toner replacement from vendor'),
 ('AST-1005', 'Routine quarterly server maintenance', '2025-03-01', '2025-03-02', 1, 3000.00, 'Completed', 'RAM and disk health check completed'),
 ('AST-1007', 'AC gas refill', '2024-04-15', '2024-04-16', 5, 2200.00, 'Completed', 'Refilled refrigerant gas');

INSERT INTO asset_disposals (asset_id, disposal_date, reason, approved_by, disposal_value) VALUES
 ('AST-1010', '2023-07-15', 'End of life - hardware failure beyond repair', 'admin', 2500.00);

INSERT INTO audit_log (username, action, entity, entity_id, details) VALUES
 ('admin', 'CREATE', 'ASSET', 'AST-1001', 'Registered new asset Dell Latitude 5440 Laptop'),
 ('admin', 'ISSUE',  'ASSET', 'AST-1001', 'Issued to Aarav Mehta (IT)'),
 ('admin', 'DISPOSE','ASSET', 'AST-1010', 'Asset disposed - hardware failure');

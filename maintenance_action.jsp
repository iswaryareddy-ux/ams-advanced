<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.sql.*" %>
<%@ page import="com.ams.util.DBConnection" %>
<%
    String username = (String) session.getAttribute("username");
    if (username == null) { response.sendRedirect("index.jsp"); return; }

    String op = request.getParameter("op");
    if (op == null) op = "";
    String redirect = "maintenance.jsp";

    try (Connection con = DBConnection.getConnection()) {

        switch (op) {

            case "create": {
                String assetId = request.getParameter("asset_id");
                String issue = request.getParameter("issue_reported");
                String serviceDate = request.getParameter("service_date");
                String vendorId = emptyToNull(request.getParameter("vendor_id"));
                String cost = emptyToNull(request.getParameter("cost"));
                String status = request.getParameter("status");
                if (status == null) status = "Open";
                String remarks = emptyToNull(request.getParameter("remarks"));

                try (PreparedStatement ps = con.prepareStatement(
                        "INSERT INTO maintenance (asset_id, issue_reported, service_date, vendor_id, cost, status, remarks) " +
                        "VALUES (?,?,?,?,?,?,?)")) {
                    ps.setString(1, assetId);
                    ps.setString(2, issue);
                    ps.setDate(3, java.sql.Date.valueOf(serviceDate));
                    if (vendorId != null) ps.setInt(4, Integer.parseInt(vendorId)); else ps.setNull(4, Types.INTEGER);
                    ps.setBigDecimal(5, cost != null ? new java.math.BigDecimal(cost) : java.math.BigDecimal.ZERO);
                    ps.setString(6, status);
                    ps.setString(7, remarks);
                    ps.executeUpdate();
                }

                if (!"Completed".equals(status)) {
                    try (PreparedStatement ps = con.prepareStatement(
                            "UPDATE assets SET status='Under Repair' WHERE asset_id=?")) {
                        ps.setString(1, assetId);
                        ps.executeUpdate();
                    }
                }

                audit(con, username, "CREATE", "MAINTENANCE", assetId, "Logged maintenance ticket: " + issue);
                redirect = "maintenance.jsp?flash=added";
                break;
            }

            case "update": {
                String maintenanceId = request.getParameter("maintenance_id");
                String assetId = request.getParameter("asset_id");
                String issue = request.getParameter("issue_reported");
                String serviceDate = request.getParameter("service_date");
                String vendorId = emptyToNull(request.getParameter("vendor_id"));
                String cost = emptyToNull(request.getParameter("cost"));
                String status = request.getParameter("status");
                if (status == null) status = "Open";
                String remarks = emptyToNull(request.getParameter("remarks"));

                boolean nowCompleted = "Completed".equals(status);

                String sql = "UPDATE maintenance SET issue_reported=?, service_date=?, vendor_id=?, cost=?, status=?, remarks=?" +
                              (nowCompleted ? ", completed_date=COALESCE(completed_date, CURDATE())" : ", completed_date=NULL") +
                              " WHERE maintenance_id=?";
                try (PreparedStatement ps = con.prepareStatement(sql)) {
                    ps.setString(1, issue);
                    ps.setDate(2, java.sql.Date.valueOf(serviceDate));
                    if (vendorId != null) ps.setInt(3, Integer.parseInt(vendorId)); else ps.setNull(3, Types.INTEGER);
                    ps.setBigDecimal(4, cost != null ? new java.math.BigDecimal(cost) : java.math.BigDecimal.ZERO);
                    ps.setString(5, status);
                    ps.setString(6, remarks);
                    ps.setInt(7, Integer.parseInt(maintenanceId));
                    ps.executeUpdate();
                }

                updateAssetStatusForMaintenance(con, assetId, nowCompleted);

                audit(con, username, "UPDATE", "MAINTENANCE", assetId, "Updated maintenance ticket #" + maintenanceId);
                redirect = "maintenance.jsp?flash=updated";
                break;
            }

            case "complete": {
                String maintenanceId = request.getParameter("maintenance_id");
                String assetId = null;

                try (PreparedStatement ps = con.prepareStatement(
                        "UPDATE maintenance SET status='Completed', completed_date=CURDATE() WHERE maintenance_id=?")) {
                    ps.setInt(1, Integer.parseInt(maintenanceId));
                    ps.executeUpdate();
                }
                try (PreparedStatement ps = con.prepareStatement("SELECT asset_id FROM maintenance WHERE maintenance_id=?")) {
                    ps.setInt(1, Integer.parseInt(maintenanceId));
                    try (ResultSet rs = ps.executeQuery()) {
                        if (rs.next()) assetId = rs.getString("asset_id");
                    }
                }

                if (assetId != null) {
                    updateAssetStatusForMaintenance(con, assetId, true);
                }

                audit(con, username, "UPDATE", "MAINTENANCE", assetId, "Marked maintenance ticket #" + maintenanceId + " as completed");
                redirect = "maintenance.jsp?flash=completed";
                break;
            }

            case "delete": {
                String maintenanceId = request.getParameter("maintenance_id");
                try (PreparedStatement ps = con.prepareStatement("DELETE FROM maintenance WHERE maintenance_id = ?")) {
                    ps.setInt(1, Integer.parseInt(maintenanceId));
                    ps.executeUpdate();
                }
                audit(con, username, "DELETE", "MAINTENANCE", maintenanceId, "Deleted maintenance record");
                redirect = "maintenance.jsp?flash=deleted";
                break;
            }

            default:
                redirect = "maintenance.jsp";
        }

    } catch (Exception ex) {
        redirect = "maintenance.jsp?flash=error";
    }

    response.sendRedirect(redirect);
%>
<%!
    private String emptyToNull(String s) {
        if (s == null) return null;
        s = s.trim();
        return s.isEmpty() ? null : s;
    }

    /**
     * When a maintenance ticket is completed, return the asset to
     * 'In Use' (if it's still assigned to an employee) or 'Available'.
     * When a ticket is reopened, send the asset back to 'Under Repair'
     * as long as it isn't Disposed.
     */
    private void updateAssetStatusForMaintenance(Connection con, String assetId, boolean completed) throws SQLException {
        if (completed) {
            try (PreparedStatement ps = con.prepareStatement(
                    "UPDATE assets SET status = CASE WHEN assigned_to IS NOT NULL THEN 'In Use' ELSE 'Available' END " +
                    "WHERE asset_id = ? AND status <> 'Disposed'")) {
                ps.setString(1, assetId);
                ps.executeUpdate();
            }
        } else {
            try (PreparedStatement ps = con.prepareStatement(
                    "UPDATE assets SET status = 'Under Repair' WHERE asset_id = ? AND status <> 'Disposed'")) {
                ps.setString(1, assetId);
                ps.executeUpdate();
            }
        }
    }

    private void audit(Connection con, String username, String action, String entity, String entityId, String details) throws SQLException {
        try (PreparedStatement ps = con.prepareStatement(
                "INSERT INTO audit_log (username, action, entity, entity_id, details) VALUES (?,?,?,?,?)")) {
            ps.setString(1, username);
            ps.setString(2, action);
            ps.setString(3, entity);
            ps.setString(4, entityId);
            ps.setString(5, details);
            ps.executeUpdate();
        }
    }
%>

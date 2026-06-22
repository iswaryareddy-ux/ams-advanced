<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.sql.*" %>
<%@ page import="com.ams.util.DBConnection" %>
<%
    String username = (String) session.getAttribute("username");
    if (username == null) { response.sendRedirect("index.jsp"); return; }

    String op = request.getParameter("op");
    if (op == null) op = "";

    String redirect = "assets.jsp";

    try (Connection con = DBConnection.getConnection()) {

        switch (op) {

            case "create": {
                String assetId   = request.getParameter("asset_id");
                String name      = request.getParameter("asset_name");
                String categoryId= request.getParameter("category_id");
                String serial    = emptyToNull(request.getParameter("serial_no"));
                String pDate     = emptyToNull(request.getParameter("purchase_date"));
                String pCost     = emptyToNull(request.getParameter("purchase_cost"));
                String vendorId  = emptyToNull(request.getParameter("vendor_id"));
                String wExpiry   = emptyToNull(request.getParameter("warranty_expiry"));
                String location  = emptyToNull(request.getParameter("location"));

                String sql = "INSERT INTO assets (asset_id, asset_name, category_id, serial_no, purchase_date, " +
                              "purchase_cost, vendor_id, warranty_expiry, location, status) " +
                              "VALUES (?,?,?,?,?,?,?,?,?, 'Available')";
                try (PreparedStatement ps = con.prepareStatement(sql)) {
                    ps.setString(1, assetId);
                    ps.setString(2, name);
                    ps.setInt(3, Integer.parseInt(categoryId));
                    ps.setString(4, serial);
                    if (pDate != null) ps.setDate(5, java.sql.Date.valueOf(pDate)); else ps.setNull(5, Types.DATE);
                    if (pCost != null) ps.setBigDecimal(6, new java.math.BigDecimal(pCost)); else ps.setBigDecimal(6, java.math.BigDecimal.ZERO);
                    if (vendorId != null) ps.setInt(7, Integer.parseInt(vendorId)); else ps.setNull(7, Types.INTEGER);
                    if (wExpiry != null) ps.setDate(8, java.sql.Date.valueOf(wExpiry)); else ps.setNull(8, Types.DATE);
                    ps.setString(9, location);
                    ps.executeUpdate();
                }
                audit(con, username, "CREATE", "ASSET", assetId, "Registered new asset: " + name);
                redirect = "assets.jsp?flash=added";
                break;
            }

            case "update": {
                String originalId = request.getParameter("original_id");
                String assetId   = request.getParameter("asset_id");
                String name      = request.getParameter("asset_name");
                String categoryId= request.getParameter("category_id");
                String serial    = emptyToNull(request.getParameter("serial_no"));
                String pDate     = emptyToNull(request.getParameter("purchase_date"));
                String pCost     = emptyToNull(request.getParameter("purchase_cost"));
                String vendorId  = emptyToNull(request.getParameter("vendor_id"));
                String wExpiry   = emptyToNull(request.getParameter("warranty_expiry"));
                String location  = emptyToNull(request.getParameter("location"));
                String status    = request.getParameter("status");

                String sql = "UPDATE assets SET asset_name=?, category_id=?, serial_no=?, purchase_date=?, " +
                              "purchase_cost=?, vendor_id=?, warranty_expiry=?, location=?, status=? " +
                              "WHERE asset_id=?";
                try (PreparedStatement ps = con.prepareStatement(sql)) {
                    ps.setString(1, name);
                    ps.setInt(2, Integer.parseInt(categoryId));
                    ps.setString(3, serial);
                    if (pDate != null) ps.setDate(4, java.sql.Date.valueOf(pDate)); else ps.setNull(4, Types.DATE);
                    if (pCost != null) ps.setBigDecimal(5, new java.math.BigDecimal(pCost)); else ps.setBigDecimal(5, java.math.BigDecimal.ZERO);
                    if (vendorId != null) ps.setInt(6, Integer.parseInt(vendorId)); else ps.setNull(6, Types.INTEGER);
                    if (wExpiry != null) ps.setDate(7, java.sql.Date.valueOf(wExpiry)); else ps.setNull(7, Types.DATE);
                    ps.setString(8, location);
                    ps.setString(9, status);
                    ps.setString(10, originalId);
                    ps.executeUpdate();
                }

                // If status changed to something other than In Use, clear assignment
                if (!"In Use".equals(status)) {
                    try (PreparedStatement ps = con.prepareStatement(
                            "UPDATE assets SET assigned_to = NULL WHERE asset_id = ?")) {
                        ps.setString(1, originalId);
                        ps.executeUpdate();
                    }
                }

                audit(con, username, "UPDATE", "ASSET", originalId, "Updated asset details");
                redirect = "assets.jsp?flash=updated";
                break;
            }

            case "delete": {
                String assetId = request.getParameter("asset_id");
                try (PreparedStatement ps = con.prepareStatement("DELETE FROM assets WHERE asset_id = ?")) {
                    ps.setString(1, assetId);
                    ps.executeUpdate();
                }
                audit(con, username, "DELETE", "ASSET", assetId, "Removed asset from registry");
                redirect = "assets.jsp?flash=deleted";
                break;
            }

            case "issue": {
                String assetId    = request.getParameter("asset_id");
                String employeeId = request.getParameter("employee_id");
                String issueDate  = request.getParameter("issue_date");
                String issuedBy   = request.getParameter("issued_by");
                String remarks    = emptyToNull(request.getParameter("remarks"));

                try (PreparedStatement ps = con.prepareStatement(
                        "UPDATE assets SET status='In Use', assigned_to=? WHERE asset_id=?")) {
                    ps.setInt(1, Integer.parseInt(employeeId));
                    ps.setString(2, assetId);
                    ps.executeUpdate();
                }
                try (PreparedStatement ps = con.prepareStatement(
                        "INSERT INTO asset_allocations (asset_id, employee_id, issue_date, issued_by, remarks) VALUES (?,?,?,?,?)")) {
                    ps.setString(1, assetId);
                    ps.setInt(2, Integer.parseInt(employeeId));
                    ps.setDate(3, java.sql.Date.valueOf(issueDate));
                    ps.setString(4, issuedBy);
                    ps.setString(5, remarks);
                    ps.executeUpdate();
                }
                audit(con, username, "ISSUE", "ASSET", assetId, "Issued to employee ID " + employeeId);
                redirect = "assets.jsp?flash=issued";
                break;
            }

            case "return": {
                String assetId = request.getParameter("asset_id");

                try (PreparedStatement ps = con.prepareStatement(
                        "UPDATE assets SET status='Available', assigned_to=NULL WHERE asset_id=?")) {
                    ps.setString(1, assetId);
                    ps.executeUpdate();
                }
                // close the most recent open allocation for this asset
                try (PreparedStatement ps = con.prepareStatement(
                        "UPDATE asset_allocations SET return_date = CURDATE() " +
                        "WHERE asset_id = ? AND return_date IS NULL " +
                        "ORDER BY issue_date DESC LIMIT 1")) {
                    ps.setString(1, assetId);
                    ps.executeUpdate();
                }
                audit(con, username, "RETURN", "ASSET", assetId, "Asset returned and marked Available");
                redirect = "assets.jsp?flash=returned";
                break;
            }

            default:
                redirect = "assets.jsp";
        }

    } catch (Exception ex) {
        redirect = "assets.jsp?flash=error";
    }

    response.sendRedirect(redirect);
%>
<%!
    private String emptyToNull(String s) {
        if (s == null) return null;
        s = s.trim();
        return s.isEmpty() ? null : s;
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

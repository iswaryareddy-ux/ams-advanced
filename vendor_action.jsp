<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.sql.*" %>
<%@ page import="com.ams.util.DBConnection" %>
<%
    String username = (String) session.getAttribute("username");
    if (username == null) { response.sendRedirect("index.jsp"); return; }

    String op = request.getParameter("op");
    if (op == null) op = "";
    String redirect = "vendors.jsp";

    try (Connection con = DBConnection.getConnection()) {

        switch (op) {

            case "create": {
                String name = request.getParameter("vendor_name");
                String contact = emptyToNull(request.getParameter("contact_person"));
                String phone = emptyToNull(request.getParameter("phone"));
                String email = emptyToNull(request.getParameter("email"));
                String address = emptyToNull(request.getParameter("address"));

                try (PreparedStatement ps = con.prepareStatement(
                        "INSERT INTO vendors (vendor_name, contact_person, phone, email, address) VALUES (?,?,?,?,?)")) {
                    ps.setString(1, name);
                    ps.setString(2, contact);
                    ps.setString(3, phone);
                    ps.setString(4, email);
                    ps.setString(5, address);
                    ps.executeUpdate();
                }
                audit(con, username, "CREATE", "VENDOR", name, "Added vendor " + name);
                redirect = "vendors.jsp?flash=added";
                break;
            }

            case "update": {
                String vendorId = request.getParameter("vendor_id");
                String name = request.getParameter("vendor_name");
                String contact = emptyToNull(request.getParameter("contact_person"));
                String phone = emptyToNull(request.getParameter("phone"));
                String email = emptyToNull(request.getParameter("email"));
                String address = emptyToNull(request.getParameter("address"));

                try (PreparedStatement ps = con.prepareStatement(
                        "UPDATE vendors SET vendor_name=?, contact_person=?, phone=?, email=?, address=? WHERE vendor_id=?")) {
                    ps.setString(1, name);
                    ps.setString(2, contact);
                    ps.setString(3, phone);
                    ps.setString(4, email);
                    ps.setString(5, address);
                    ps.setInt(6, Integer.parseInt(vendorId));
                    ps.executeUpdate();
                }
                audit(con, username, "UPDATE", "VENDOR", vendorId, "Updated vendor " + name);
                redirect = "vendors.jsp?flash=updated";
                break;
            }

            case "delete": {
                String vendorId = request.getParameter("vendor_id");

                int linked = 0;
                try (PreparedStatement ps = con.prepareStatement(
                        "SELECT (SELECT COUNT(*) FROM assets WHERE vendor_id = ?) + " +
                        "(SELECT COUNT(*) FROM maintenance WHERE vendor_id = ?) AS c")) {
                    ps.setInt(1, Integer.parseInt(vendorId));
                    ps.setInt(2, Integer.parseInt(vendorId));
                    try (ResultSet rs = ps.executeQuery()) {
                        if (rs.next()) linked = rs.getInt("c");
                    }
                }

                if (linked > 0) {
                    redirect = "vendors.jsp?flash=blocked";
                } else {
                    try (PreparedStatement ps = con.prepareStatement("DELETE FROM vendors WHERE vendor_id = ?")) {
                        ps.setInt(1, Integer.parseInt(vendorId));
                        ps.executeUpdate();
                    }
                    audit(con, username, "DELETE", "VENDOR", vendorId, "Removed vendor from directory");
                    redirect = "vendors.jsp?flash=deleted";
                }
                break;
            }

            default:
                redirect = "vendors.jsp";
        }

    } catch (Exception ex) {
        redirect = "vendors.jsp?flash=error";
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

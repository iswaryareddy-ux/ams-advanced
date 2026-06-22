<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.sql.*" %>
<%@ page import="com.ams.util.DBConnection" %>
<%
    String username = (String) session.getAttribute("username");
    if (username == null) { response.sendRedirect("index.jsp"); return; }

    String op = request.getParameter("op");
    if (op == null) op = "";
    String redirect = "employees.jsp";

    try (Connection con = DBConnection.getConnection()) {

        switch (op) {

            case "create": {
                String name = request.getParameter("name");
                String dept = emptyToNull(request.getParameter("department"));
                String desig = emptyToNull(request.getParameter("designation"));
                String phone = emptyToNull(request.getParameter("phone"));
                String email = emptyToNull(request.getParameter("email"));

                try (PreparedStatement ps = con.prepareStatement(
                        "INSERT INTO employees (name, department, designation, phone, email) VALUES (?,?,?,?,?)")) {
                    ps.setString(1, name);
                    ps.setString(2, dept);
                    ps.setString(3, desig);
                    ps.setString(4, phone);
                    ps.setString(5, email);
                    ps.executeUpdate();
                }
                audit(con, username, "CREATE", "EMPLOYEE", name, "Added employee " + name);
                redirect = "employees.jsp?flash=added";
                break;
            }

            case "update": {
                String employeeId = request.getParameter("employee_id");
                String name = request.getParameter("name");
                String dept = emptyToNull(request.getParameter("department"));
                String desig = emptyToNull(request.getParameter("designation"));
                String phone = emptyToNull(request.getParameter("phone"));
                String email = emptyToNull(request.getParameter("email"));
                String status = request.getParameter("status");
                if (status == null) status = "Active";

                try (PreparedStatement ps = con.prepareStatement(
                        "UPDATE employees SET name=?, department=?, designation=?, phone=?, email=?, status=? WHERE employee_id=?")) {
                    ps.setString(1, name);
                    ps.setString(2, dept);
                    ps.setString(3, desig);
                    ps.setString(4, phone);
                    ps.setString(5, email);
                    ps.setString(6, status);
                    ps.setInt(7, Integer.parseInt(employeeId));
                    ps.executeUpdate();
                }
                audit(con, username, "UPDATE", "EMPLOYEE", employeeId, "Updated employee " + name);
                redirect = "employees.jsp?flash=updated";
                break;
            }

            case "delete": {
                String employeeId = request.getParameter("employee_id");

                // Don't allow deletion while assets are still assigned
                int active = 0;
                try (PreparedStatement ps = con.prepareStatement(
                        "SELECT COUNT(*) c FROM assets WHERE assigned_to = ? AND status = 'In Use'")) {
                    ps.setInt(1, Integer.parseInt(employeeId));
                    try (ResultSet rs = ps.executeQuery()) {
                        if (rs.next()) active = rs.getInt("c");
                    }
                }

                if (active > 0) {
                    redirect = "employees.jsp?flash=blocked";
                } else {
                    try (PreparedStatement ps = con.prepareStatement("DELETE FROM employees WHERE employee_id = ?")) {
                        ps.setInt(1, Integer.parseInt(employeeId));
                        ps.executeUpdate();
                    }
                    audit(con, username, "DELETE", "EMPLOYEE", employeeId, "Removed employee from directory");
                    redirect = "employees.jsp?flash=deleted";
                }
                break;
            }

            default:
                redirect = "employees.jsp";
        }

    } catch (Exception ex) {
        redirect = "employees.jsp?flash=error";
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

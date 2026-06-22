<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.sql.*" %>
<%@ page import="com.ams.util.DBConnection" %>
<%
    String username = request.getParameter("username");
    String password = request.getParameter("password");
    String role      = request.getParameter("role");

    if (username == null) username = "";
    if (password == null) password = "";
    if (role == null) role = "User";

    boolean success = false;

    String sql = "SELECT u.user_id, u.username, u.full_name, u.role, u.status, "
                + "       e.employee_id, e.department "
                + "FROM users u "
                + "LEFT JOIN employees e ON e.employee_id = u.employee_id "
                + "WHERE u.username = ? AND u.password = ? AND u.role = ?";

    try (Connection con = DBConnection.getConnection();
         PreparedStatement ps = con.prepareStatement(sql)) {

        ps.setString(1, username);
        ps.setString(2, password); // NOTE: store hashed passwords (e.g. BCrypt) in production
        ps.setString(3, role);

        try (ResultSet rs = ps.executeQuery()) {
            if (rs.next()) {
                if ("Inactive".equalsIgnoreCase(rs.getString("status"))) {
                    response.sendRedirect("index.jsp?error=1");
                    return;
                }
                success = true;

                session.setAttribute("userId",   rs.getInt("user_id"));
                session.setAttribute("username", rs.getString("username"));
                session.setAttribute("fullName", rs.getString("full_name"));
                session.setAttribute("role",     rs.getString("role"));
                session.setAttribute("employeeId", rs.getObject("employee_id"));
                session.setAttribute("department", rs.getString("department"));

                // update last login
                try (PreparedStatement up = con.prepareStatement(
                        "UPDATE users SET last_login = NOW() WHERE user_id = ?")) {
                    up.setInt(1, rs.getInt("user_id"));
                    up.executeUpdate();
                }

                // audit trail
                try (PreparedStatement log = con.prepareStatement(
                        "INSERT INTO audit_log (username, action, entity, entity_id, details) VALUES (?, 'LOGIN', 'USER', ?, 'User signed in')")) {
                    log.setString(1, rs.getString("username"));
                    log.setString(2, String.valueOf(rs.getInt("user_id")));
                    log.executeUpdate();
                }
            }
        }
    } catch (Exception ex) {
        // In production, log ex to a file instead of printing
        response.sendRedirect("index.jsp?error=1");
        return;
    }

    if (success) {
        response.sendRedirect("dashboard.jsp");
    } else {
        response.sendRedirect("index.jsp?error=1");
    }
%>

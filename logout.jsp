<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.sql.*" %>
<%@ page import="com.ams.util.DBConnection" %>
<%
    String username = (String) session.getAttribute("username");

    if (username != null) {
        try (Connection con = DBConnection.getConnection();
             PreparedStatement log = con.prepareStatement(
                "INSERT INTO audit_log (username, action, entity, entity_id, details) VALUES (?, 'LOGOUT', 'USER', ?, 'User signed out')")) {
            log.setString(1, username);
            log.setString(2, username);
            log.executeUpdate();
        } catch (Exception ex) {
            // ignore logging failure on logout
        }
    }

    session.invalidate();
    response.sendRedirect("index.jsp?loggedout=1");
%>

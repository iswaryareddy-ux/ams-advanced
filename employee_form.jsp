<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.sql.*" %>
<%@ page import="java.util.*" %>
<%@ page import="com.ams.util.DBConnection" %>
<%
    String id = request.getParameter("id");
    boolean isEdit = (id != null && !id.isEmpty());

    String pageTitle = isEdit ? "Edit employee" : "Add employee";
    String pageSubtitle = isEdit ? "Update this employee's details" : "Add a new employee to the directory";
    String activePage = "employees";

    Map<String,Object> emp = null;
    boolean dbOk = true;

    if (isEdit) {
        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement("SELECT * FROM employees WHERE employee_id = ?")) {
            ps.setInt(1, Integer.parseInt(id));
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    emp = new HashMap<>();
                    emp.put("employee_id", rs.getInt("employee_id"));
                    emp.put("name", rs.getString("name"));
                    emp.put("department", rs.getString("department"));
                    emp.put("designation", rs.getString("designation"));
                    emp.put("phone", rs.getString("phone"));
                    emp.put("email", rs.getString("email"));
                    emp.put("status", rs.getString("status"));
                }
            }
        } catch (Exception ex) {
            dbOk = false;
        }
        if (emp == null && dbOk) {
            response.sendRedirect("employees.jsp");
            return;
        }
    }
%>
<%@ include file="includes/header.jsp" %>

  <div class="card" style="max-width:640px;">
    <div class="card-head">
      <div>
        <h2><%= isEdit ? "Editing " + emp.get("name") : "New employee" %></h2>
        <div class="hint">Fields marked with <span class="req">*</span> are required.</div>
      </div>
      <a href="employees.jsp" class="btn btn-ghost btn-sm">
        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><line x1="19" y1="12" x2="5" y2="12"/><polyline points="12 19 5 12 12 5"/></svg>
        Back to employees
      </a>
    </div>

    <div class="card-pad">
      <form action="employee_action.jsp" method="post" class="form-grid">
        <input type="hidden" name="op" value="<%= isEdit ? "update" : "create" %>">
        <% if (isEdit) { %><input type="hidden" name="employee_id" value="<%= emp.get("employee_id") %>"><% } %>

        <div class="field full">
          <label for="name">Full name <span class="req">*</span></label>
          <input type="text" id="name" name="name" required placeholder="e.g. Karan Verma"
                 value="<%= isEdit ? emp.get("name") : "" %>">
        </div>

        <div class="field">
          <label for="department">Department</label>
          <input type="text" id="department" name="department" placeholder="e.g. IT, Finance, Marketing"
                 value="<%= isEdit && emp.get("department") != null ? emp.get("department") : "" %>">
        </div>

        <div class="field">
          <label for="designation">Designation</label>
          <input type="text" id="designation" name="designation" placeholder="e.g. Network Engineer"
                 value="<%= isEdit && emp.get("designation") != null ? emp.get("designation") : "" %>">
        </div>

        <div class="field">
          <label for="phone">Phone</label>
          <input type="text" id="phone" name="phone" placeholder="10-digit mobile number"
                 value="<%= isEdit && emp.get("phone") != null ? emp.get("phone") : "" %>">
        </div>

        <div class="field">
          <label for="email">Email</label>
          <input type="email" id="email" name="email" placeholder="name@company.com"
                 value="<%= isEdit && emp.get("email") != null ? emp.get("email") : "" %>">
        </div>

        <% if (isEdit) { %>
        <div class="field full">
          <label for="status">Status</label>
          <select id="status" name="status">
            <option value="Active" <%= "Active".equals(emp.get("status")) ? "selected" : "" %>>Active</option>
            <option value="Inactive" <%= "Inactive".equals(emp.get("status")) ? "selected" : "" %>>Inactive</option>
          </select>
          <div class="help">Inactive employees stay on record for history but cannot be issued new assets.</div>
        </div>
        <% } %>

        <div class="form-actions full">
          <a href="employees.jsp" class="btn btn-ghost">Cancel</a>
          <button type="submit" class="btn btn-accent"><%= isEdit ? "Save changes" : "Add employee" %></button>
        </div>
      </form>
    </div>
  </div>

<%@ include file="includes/footer.jsp" %>

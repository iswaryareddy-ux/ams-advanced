<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.sql.*" %>
<%@ page import="java.util.*" %>
<%@ page import="com.ams.util.DBConnection" %>
<%
    String id = request.getParameter("id");
    boolean isEdit = (id != null && !id.isEmpty());

    String pageTitle = isEdit ? "Edit vendor" : "Add vendor";
    String pageSubtitle = isEdit ? "Update this vendor's details" : "Add a new supplier or service provider";
    String activePage = "vendors";

    Map<String,Object> vendor = null;
    boolean dbOk = true;

    if (isEdit) {
        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement("SELECT * FROM vendors WHERE vendor_id = ?")) {
            ps.setInt(1, Integer.parseInt(id));
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    vendor = new HashMap<>();
                    vendor.put("vendor_id", rs.getInt("vendor_id"));
                    vendor.put("vendor_name", rs.getString("vendor_name"));
                    vendor.put("contact_person", rs.getString("contact_person"));
                    vendor.put("phone", rs.getString("phone"));
                    vendor.put("email", rs.getString("email"));
                    vendor.put("address", rs.getString("address"));
                }
            }
        } catch (Exception ex) {
            dbOk = false;
        }
        if (vendor == null && dbOk) {
            response.sendRedirect("vendors.jsp");
            return;
        }
    }
%>
<%@ include file="includes/header.jsp" %>

  <div class="card" style="max-width:640px;">
    <div class="card-head">
      <div>
        <h2><%= isEdit ? "Editing " + vendor.get("vendor_name") : "New vendor" %></h2>
        <div class="hint">Fields marked with <span class="req">*</span> are required.</div>
      </div>
      <a href="vendors.jsp" class="btn btn-ghost btn-sm">
        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><line x1="19" y1="12" x2="5" y2="12"/><polyline points="12 19 5 12 12 5"/></svg>
        Back to vendors
      </a>
    </div>

    <div class="card-pad">
      <form action="vendor_action.jsp" method="post" class="form-grid">
        <input type="hidden" name="op" value="<%= isEdit ? "update" : "create" %>">
        <% if (isEdit) { %><input type="hidden" name="vendor_id" value="<%= vendor.get("vendor_id") %>"><% } %>

        <div class="field full">
          <label for="vendor_name">Vendor name <span class="req">*</span></label>
          <input type="text" id="vendor_name" name="vendor_name" required placeholder="e.g. Dell Technologies India"
                 value="<%= isEdit ? vendor.get("vendor_name") : "" %>">
        </div>

        <div class="field">
          <label for="contact_person">Contact person</label>
          <input type="text" id="contact_person" name="contact_person" placeholder="e.g. Rohit Sharma"
                 value="<%= isEdit && vendor.get("contact_person") != null ? vendor.get("contact_person") : "" %>">
        </div>

        <div class="field">
          <label for="phone">Phone</label>
          <input type="text" id="phone" name="phone" placeholder="10-digit contact number"
                 value="<%= isEdit && vendor.get("phone") != null ? vendor.get("phone") : "" %>">
        </div>

        <div class="field">
          <label for="email">Email</label>
          <input type="email" id="email" name="email" placeholder="sales@vendor.com"
                 value="<%= isEdit && vendor.get("email") != null ? vendor.get("email") : "" %>">
        </div>

        <div class="field">
          <label for="address">Address</label>
          <input type="text" id="address" name="address" placeholder="Office address"
                 value="<%= isEdit && vendor.get("address") != null ? vendor.get("address") : "" %>">
        </div>

        <div class="form-actions full">
          <a href="vendors.jsp" class="btn btn-ghost">Cancel</a>
          <button type="submit" class="btn btn-accent"><%= isEdit ? "Save changes" : "Add vendor" %></button>
        </div>
      </form>
    </div>
  </div>

<%@ include file="includes/footer.jsp" %>

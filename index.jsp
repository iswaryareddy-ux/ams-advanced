<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%
    // If already logged in, go straight to the dashboard
    if (session.getAttribute("username") != null) {
        response.sendRedirect("dashboard.jsp");
        return;
    }
    String error = request.getParameter("error");
    String loggedOut = request.getParameter("loggedout");
%>
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Sign in &middot; AMS</title>
  <link rel="stylesheet" href="css/style.css">
</head>
<body>
<div class="login-page">

  <aside class="login-aside">
    <div class="brand">
      <div class="brand-mark">
        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect x="3" y="3" width="7" height="7" rx="1"/><rect x="14" y="3" width="7" height="7" rx="1"/><rect x="3" y="14" width="7" height="7" rx="1"/><rect x="14" y="14" width="7" height="7" rx="1"/></svg>
      </div>
      <div class="brand-text">
        <strong style="color:#fff;">AMS</strong>
        <span>Asset Manager</span>
      </div>
    </div>

    <div class="pitch">
      <h2>Every asset, tagged, tracked and accounted for.</h2>
      <p>Register hardware and software, issue it to your team, schedule maintenance,
         and keep an audit trail &mdash; from purchase to disposal.</p>

      <div class="tag-rail">
        <span class="tag">AST-1001 &middot; Latitude 5440</span>
        <span class="tag">AST-1004 &middot; Catalyst 2960</span>
        <span class="tag">AST-1009 &middot; Epson Projector</span>
      </div>
    </div>

    <div class="foot-note">&copy; <%= java.time.Year.now() %> Asset Management System &middot; Internal use only</div>
  </aside>

  <main class="login-main">
    <div class="login-card">
      <h1>Welcome back</h1>
      <p class="lead">Sign in with your company credentials to continue.</p>

      <% if ("1".equals(error)) { %>
        <div class="alert alert-error">
          <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="10"/><line x1="12" y1="8" x2="12" y2="12"/><line x1="12" y1="16" x2="12.01" y2="16"/></svg>
          <div>Incorrect username, password, or role. Please try again.</div>
        </div>
      <% } %>
      <% if ("1".equals(loggedOut)) { %>
        <div class="alert alert-success" data-autohide>
          <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M20 6 9 17l-5-5"/></svg>
          <div>You have been signed out.</div>
        </div>
      <% } %>

      <form action="login_action.jsp" method="post">

        <div class="role-toggle">
          <input type="radio" name="role" id="roleAdmin" value="Admin" checked>
          <label for="roleAdmin" class="checked">Admin</label>
          <input type="radio" name="role" id="roleUser" value="User">
          <label for="roleUser">User</label>
        </div>

        <div class="field">
          <label for="username">Username</label>
          <input type="text" id="username" name="username" placeholder="e.g. admin" required autofocus>
        </div>

        <div class="field">
          <label for="password">Password</label>
          <input type="password" id="password" name="password" placeholder="••••••••" required>
        </div>

        <div class="meta-row">
          <label style="display:flex; align-items:center; gap:.4rem; font-weight:500; color:var(--ink-soft);">
            <input type="checkbox" name="remember" style="width:auto;"> Remember me
          </label>
          <a href="#">Forgot password?</a>
        </div>

        <button type="submit" class="btn btn-accent">Sign in</button>
      </form>

      <p class="field" style="margin-top:1.5rem; font-size:.78rem; color:var(--ink-soft);">
        Demo accounts &mdash; Admin: <span class="mono">admin / admin123</span> &middot;
        User: <span class="mono">kverma / user123</span>
      </p>
    </div>
  </main>

</div>
<script src="js/script.js"></script>
</body>
</html>

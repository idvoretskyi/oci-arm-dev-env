# Security Guidelines

## 🔒 **Important Security Considerations**

### **1. Change Default Password**
**CRITICAL**: The default password in `helm-chart/code-server/values.yaml` is a placeholder and MUST be changed before deployment.

```yaml
codeServer:
  password: "YOUR-SECURE-PASSWORD-HERE"  # CHANGE THIS!
```

**How to set a secure password:**
```bash
# During deployment
helm install code-server ./helm-chart/code-server -n code-server --set codeServer.password=your-secure-password

# Or upgrade existing deployment
helm upgrade code-server ./helm-chart/code-server -n code-server --set codeServer.password=your-secure-password
```

### **2. SSH Key Management**
- Use strong SSH key pairs (RSA 4096-bit or Ed25519)
- Store private keys securely and never commit them to version control
- The deployment script reads SSH public keys from `~/.ssh/` directory
- Ensure SSH keys are properly protected with passphrases

### **3. Network Security**
- The deployment creates security lists with minimal required ports
- SSH (22), HTTP (80), HTTPS (443), and K3s API (6443) are exposed
- Consider using a VPN or bastion host for additional security
- Regularly review and update security group rules

### **4. OCI Credentials**
- Store OCI credentials securely in `~/.oci/config`
- Use IAM policies with minimal required permissions
- Rotate API keys regularly
- Never commit OCI credentials to version control

### **5. Kubernetes Security**
- Code-server runs with restricted security contexts
- Passwords are stored in Kubernetes secrets
- Use network policies for additional pod-to-pod security
- Regularly update container images

### **6. SSL/TLS Configuration**
- Configure SSL certificates for production use
- Use Let's Encrypt or your organization's certificates
- Update ingress annotations for proper SSL termination

### **7. Regular Updates**
- Keep OCI instances updated with security patches
- Update container images regularly
- Monitor for security vulnerabilities in dependencies

### **8. Access Control**
- Use strong passwords for code-server access
- Consider implementing OAuth or SSO integration
- Limit access to development environments
- Implement proper user management policies

### **9. Data Protection**
- Backup persistent volume data regularly
- Use encryption for sensitive data
- Implement proper data retention policies
- Consider compliance requirements (GDPR, HIPAA, etc.)

### **10. Monitoring and Logging**
- Enable logging for security events
- Monitor for unauthorized access attempts
- Set up alerts for suspicious activities
- Review logs regularly

## 🚨 **Security Checklist Before Deployment**

- [ ] Changed default password in values.yaml
- [ ] Configured strong SSH keys
- [ ] Reviewed network security groups
- [ ] Secured OCI credentials
- [ ] Configured SSL certificates (if needed)
- [ ] Set up monitoring and logging
- [ ] Implemented backup procedures
- [ ] Reviewed access control policies

## 📧 **Reporting Security Issues**

If you discover a security vulnerability, please report it responsibly:

1. **Do not** create a public GitHub issue
2. Contact the maintainers privately
3. Provide detailed information about the vulnerability
4. Allow reasonable time for the issue to be addressed

## 🔄 **Security Updates**

This project follows security best practices and will be updated regularly to address any security concerns. Please:

- Watch the repository for security updates
- Keep your deployments updated
- Follow security announcements
- Implement recommended security measures

## 📚 **Additional Resources**

- [OCI Security Best Practices](https://docs.oracle.com/en-us/iaas/Content/Security/Concepts/security_guide.htm)
- [Kubernetes Security](https://kubernetes.io/docs/concepts/security/)
- [Code-Server Security](https://github.com/coder/code-server/blob/main/docs/security.md)
- [Helm Security](https://helm.sh/docs/topics/security/)
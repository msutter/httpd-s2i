FROM openshift/base-centos7

EXPOSE 8080

# Install Apache httpd from www.softwarecollections.org
RUN yum install -y \
  https://www.softwarecollections.org/repos/rhscl/httpd24/epel-7-x86_64/noarch/rhscl-httpd24-epel-7-x86_64-1-2.noarch.rpm && \
    yum install -y --setopt=tsflags=nodocs httpd24 && \
    yum clean all -y

LABEL io.k8s.description="Platform for building and running httpd applications" \
      io.k8s.display-name="Apache 2.4" \
      io.openshift.expose-services="8080:http" \
      io.openshift.tags="builder,httpd" \
      # this label tells s2i where to find its mandatory scripts
      # (run, assemble, save-artifacts)
      io.openshift.s2i.script-url="image:///usr/libexec/s2i"

# Copy the S2I scripts from the specific language image to /usr/libexec/s2i (where we set the label above)
COPY ./.s2i/bin/* /usr/libexec/s2i/

# Each language image can have 'contrib' a directory with extra files needed to
# run and build the applications.
COPY ./contrib/ /opt/app-root

# In order to drop the root user, we have to make some directories world
# writeable as OpenShift default security model is to run the container under
# random UID.
RUN sed -i -f /opt/app-root/etc/httpdconf.sed /opt/rh/httpd24/root/etc/httpd/conf/httpd.conf && \
    head -n151 /opt/rh/httpd24/root/etc/httpd/conf/httpd.conf | tail -n1 | grep "AllowOverride All" || exit && \
    chmod -R a+rwx /opt/rh/httpd24/root/var/run/httpd && \
    chown -R 1001:1001 /opt/app-root

USER 1001

# Set the default CMD to print the usage of the language image
CMD ["usage"]
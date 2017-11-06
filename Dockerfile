# Use jbossdemocentral/developer as the base
FROM jbossdemocentral/developer

# Maintainer details
MAINTAINER Andrew Block, Eric D. Schabell

# Environment Variables 
ENV BRMS_HOME /opt/jboss/brms/jboss-eap-7.0
ENV BRMS_VERSION_MAJOR 6
ENV BRMS_VERSION_MINOR 4
ENV BRMS_VERSION_MICRO 0
ENV BRMS_VERSION_PATCH GA

ENV EAP_VERSION_MAJOR 7
ENV EAP_VERSION_MINOR 0
ENV EAP_VERSION_MICRO 0

ENV EAP_INSTALLER=jboss-eap-$EAP_VERSION_MAJOR.$EAP_VERSION_MINOR.$EAP_VERSION_MICRO-installer.jar
ENV BRMS_DEPLOYABLE=jboss-brms-$BRMS_VERSION_MAJOR.$BRMS_VERSION_MINOR.$BRMS_VERSION_MICRO.$BRMS_VERSION_PATCH-deployable-eap7.x.zip

# ADD Installation and Management Files
COPY support/installation-eap support/installation-eap.variables installs/$BRMS_DEPLOYABLE installs/$EAP_INSTALLER support/fix-permissions /opt/jboss/

# Update Permissions on Installers
USER root
RUN chown 1000:1000 /opt/jboss/$EAP_INSTALLER /opt/jboss/$BRMS_DEPLOYABLE

# Prepare and run installer and cleanup installation components
RUN sed -i "s:<installpath>.*</installpath>:<installpath>$BRMS_HOME</installpath>:" /opt/jboss/installation-eap \
    && java -jar /opt/jboss/$EAP_INSTALLER /opt/jboss/installation-eap -variablefile /opt/jboss/installation-eap.variables \
    && unzip -qo /opt/jboss/$BRMS_DEPLOYABLE  -d $BRMS_HOME/.. \
    && /opt/jboss/fix-permissions $BRMS_HOME \
    && rm -rf /opt/jboss/$BRMS_DEPLOYABLE /opt/jboss/$EAP_INSTALLER /opt/jboss/installation-eap /opt/jboss/installation-eap.variables $BRMS_HOME/standalone/configuration/standalone_xml_history/ \
    && $BRMS_HOME/bin/add-user.sh -a -r ApplicationRealm -u erics -p jbossbrms1! -ro analyst,admin,manager,user,kie-server,kiemgmt,rest-all --silent

# Copy demo and support files
COPY support/brms-demo-niogit $BRMS_HOME/bin/.niogit
COPY support/standalone.xml $BRMS_HOME/standalone/configuration/standalone.xml
COPY projects /opt/jboss/brms-projects
COPY support/libs /opt/jboss/brms-projects/libs
COPY support/userinfo.properties $BRMS_HOME/standalone/deployments/business-central.war/WEB-INF/classes/
COPY support/postgresql /opt/jboss/brms/jboss-eap-7.0/modules/system/layers/base/org/postgresql
COPY support/start.sh /opt/jboss/

# Run Demo Maven build and cleanup
RUN mvn install:install-file -Dfile=/opt/jboss/brms-projects/libs/coolstore-2.0.0.jar -DgroupId=com.redhat -DartifactId=coolstore -Dversion=2.0.0 -Dpackaging=jar \
  && mvn clean install -f /opt/jboss/brms-projects/brms-coolstore-demo/pom.xml \
  && cp /opt/jboss/brms-projects/brms-coolstore-demo/target/brms-coolstore-demo.war $BRMS_HOME/standalone/deployments/ \
  && chown -R 1000:root $BRMS_HOME \
  && /opt/jboss/fix-permissions $BRMS_HOME/bin/.niogit \
  && /opt/jboss/fix-permissions $BRMS_HOME/standalone/configuration/standalone.xml \
  && /opt/jboss/fix-permissions $BRMS_HOME/standalone/deployments/brms-coolstore-demo.war \
  && /opt/jboss/fix-permissions $BRMS_HOME/standalone/deployments/business-central.war/WEB-INF/classes/userinfo.properties \
  && /opt/jboss/fix-permissions /etc/passwd \
  && /opt/jboss/fix-permissions /etc/group \
  && /opt/jboss/fix-permissions /opt/jboss/start.sh \
  && /opt/jboss/fix-permissions /opt/jboss/.m2 \
  && rm -rf /opt/jboss/brms-projects \
  && sed -i 's/ExampleDS/PostgresDS/g' $BRMS_HOME/standalone/deployments/business-central.war/WEB-INF/classes/META-INF/persistence.xml \
  && sed -i 's/H2Dialect/PostgreSQLDialect/g' $BRMS_HOME/standalone/deployments/business-central.war/WEB-INF/classes/META-INF/persistence.xml \
  && chmod +x /opt/jboss/start.sh 

# Run as JBoss 
USER 1000

# Expose Ports
EXPOSE 9990 9999 8080 9418 8001

# Default Command
CMD ["/bin/bash"]

# Helper script
ENTRYPOINT ["/opt/jboss/start.sh"]

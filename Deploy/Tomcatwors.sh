#!/bin/bash
echo -----------------
echo Iniciando Script
echo -----------------
echo instalando JAVA
echo 

## Variables
usuario=x002896
cert=

chmod 755 /opt/genesys/jdk-8u241-linux-x64.rpm
rpm -i /opt/genesys/jdk-8u241-linux-x64.rpm
echo generando variable JAVA_HOME
echo '# Java
export JAVA_HOME=/usr/java/default' >> /home/$usuario/.bash_profile
echo -----------------
echo Servicio
echo -----------------
echo 
echo Generando servicio en init.d
echo '#!/bin/sh
# chkconfig: 23 99 1
# Required-Start:    $local_fs $network
# Required-Stop:     $local_fs $network' > genesys-was_$HOSTNAME
echo "# Short-Description: Init script for was_"$HOSTNAME >> genesys-was_$HOSTNAME
echo "# Description:       A simple daemon wrapper for was_"$HOSTNAME >> genesys-was_$HOSTNAME
echo >> genesys-was_$HOSTNAME
echo '#Get killproc and other funcitons
. /etc/init.d/functions
' >> genesys-was_$HOSTNAME
echo "SERVICE_NAME=was_"$HOSTNAME >> genesys-was_$HOSTNAME
echo "USER="$usuario >> genesys-was_$HOSTNAME
echo 'SUBIT="su - $USER -c "
KILL_TIME=60


#TODO pass on the network configuration as a #n parameter??  that shoudl allow us to have multipe instances on a single node
PIDFILE=/var/run/${SERVICE_NAME}.pid


start() {
  if [ -f ${PIDFILE} ]; then
   #verify if the process is actually still running under this pid
   OLDPID=`cat ${PIDFILE}`
   #See if the pid is running, making sure that we are not tracking the grep process itself
   RESULT=`ps -ef | grep ${OLDPID} | grep -v grep` 

   if [ -n "${RESULT}" ]; then
     echo "Script already running! Exiting"
     exit 255
   fi

  fi



  echo "Starting up $SERVICE"

  #TODO look at using a more standard daemon function
  PID=`su - $USER -s /bin/bash -c '\''cd /opt/genesys/apache-tomcat-8.5.72/bin/; sh TomcatST.sh >> /dev/null 2>&1 & echo $!'\''`
  RETVAL=$?

  #grab pid of this process and update the pid file with it
  echo "$PID" > $PIDFILE

  if [ ! -z "$SUBIT" ]; then
    chown $USER $PIDFILE
  fi

}
# Restart the service FOO
stop() {
    
    if [ -f ${PIDFILE} ]; then
      cd /opt/genesys/apache-tomcat-8.5.72/bin/; sh TomcatSH.sh
      RETVAL=$?
      echo "[`date -u +%Y-%m-%dT%T.%3NZ`] (sys) Stopped"

      rm ${PIDFILE}
    else
      echo "No ${PIDFILE} exists, nothing to stop"
    fi
}


case "$1" in
  start)
        start
        ;;
  stop)
        stop
        ;;
  status)
  #//not sure if we feed the prog itself
        status -p ${PIDFILE} ''
        RETVAL=$?
        ;;
  restart|reload|condrestart)
        stop
        start
        ;;
  *)
        echo $"Usage: $0 {start|stop|restart|reload|status}"
        RETVAL=1
esac
exit $RETVAL
' >> genesys-was_$HOSTNAME
echo archivo genesys-was_$HOSTNAME generado
chmod 755 /opt/genesys/genesys-was_$HOSTNAME
mv /opt/genesys/genesys-was_$HOSTNAME /etc/init.d/
echo permisos brindados y movido al init.d
echo 
echo -----------------
echo Tomcat
echo -----------------
echo 
echo Creando TomcatSH.sh
echo '#!/bin/bash
# locate running WB and kill the running instance
ps -efww | grep "/opt/genesys/apache-tomcat-8.5.72" | grep -v grep | awk '\''{print $2}'\'' | xargs -n1 kill -9 '> TomcatSH.sh
echo Creado TomcatSH.sh
echo 
echo Creando TomcatST.sh
echo '#!/bin/bash
# locate running WB and kill the running instance
ps -efww | grep "/opt/genesys/apache-tomcat-8.5.72" | grep -v grep | awk '\''{print $2}'\'' | xargs -n1 kill -9 
//bin/java -Djava.util.logging.config.file=/opt/genesys/apache-tomcat-8.5.72/conf/logging.properties -Djava.util.logging.manager=org.apache.juli.ClassLoaderLogManager -Djdk.tls.ephemeralDHKeySize=2048 -Djava.protocol.handler.pkgs=org.apache.catalina.webresources -Dorg.apache.catalina.security.SecurityListener.UMASK=0027 -Dignore.endorsed.dirs= -classpath /opt/genesys/apache-tomcat-8.5.72/bin/bootstrap.jar:/opt/genesys/apache-tomcat-8.5.72/bin/tomcat-juli.jar -Dcatalina.base=/opt/genesys/apache-tomcat-8.5.72 -Dcatalina.home=/opt/genesys/apache-tomcat-8.5.72 -Djava.io.tmpdir=/opt/genesys/apache-tomcat-8.5.72/temp org.apache.catalina.startup.Bootstrap start' > TomcatST.sh
echo Creado TomcatST.sh
echo 
echo Moviendo ST SH y dando permisos 
mv /opt/genesys/TomcatST.sh /opt/genesys/apache-tomcat-8.5.72/bin/
mv /opt/genesys/TomcatSH.sh /opt/genesys/apache-tomcat-8.5.72/bin/
chmod 755 /opt/genesys/apache-tomcat-8.5.72/bin/TomcatST.sh
chmod 755 /opt/genesys/apache-tomcat-8.5.72/bin/TomcatSH.sh
echo 
echo -----------------
echo Genero XMLs
echo -----------------
echo 
echo Generando Context.XML para Manager
echo '<?xml version="1.0" encoding="UTF-8"?>
<!--
  Licensed to the Apache Software Foundation (ASF) under one or more
  contributor license agreements.  See the NOTICE file distributed with
  this work for additional information regarding copyright ownership.
  The ASF licenses this file to You under the Apache License, Version 2.0
  (the "License"); you may not use this file except in compliance with
  the License.  You may obtain a copy of the License at

      http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
-->
<Context antiResourceLocking="false" privileged="true" >
  <CookieProcessor className="org.apache.tomcat.util.http.Rfc6265CookieProcessor"
                   sameSiteCookies="strict" />
<!--
  <Valve className="org.apache.catalina.valves.RemoteAddrValve"
         allow="127\.\d+\.\d+\.\d+|::1|0:0:0:0:0:0:0:1|10.66.72.*" />
-->
  <Manager sessionAttributeValueClassNameFilter="java\.lang\.(?:Boolean|Integer|Long|Number|String)|org\.apache\.catalina\.filters\.CsrfPreventionFilter\$LruCache(?:\$1)?|java\.util\.(?:Linked)?HashMap"/>
</Context>
'> context.xml
echo 
echo Generando tomcat-users.xml
echo '<?xml version="1.0" encoding="UTF-8"?>
<!--
  Licensed to the Apache Software Foundation (ASF) under one or more
  contributor license agreements.  See the NOTICE file distributed with
  this work for additional information regarding copyright ownership.
  The ASF licenses this file to You under the Apache License, Version 2.0
  (the "License"); you may not use this file except in compliance with
  the License.  You may obtain a copy of the License at

      http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
-->
<tomcat-users xmlns="http://tomcat.apache.org/xml"
              xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
              xsi:schemaLocation="http://tomcat.apache.org/xml tomcat-users.xsd"
              version="1.0">
<!--
  By default, no user is included in the "manager-gui" role required
  to operate the "/manager/html" web application.  If you wish to use this app,
  you must define such a user - the username and password are arbitrary.

  Built-in Tomcat manager roles:
    - manager-gui    - allows access to the HTML GUI and the status pages
    - manager-script - allows access to the HTTP API and the status pages
    - manager-jmx    - allows access to the JMX proxy and the status pages
    - manager-status - allows access to the status pages only

  The users below are wrapped in a comment and are therefore ignored. If you
  wish to configure one or more of these users for use with the manager web
  application, do not forget to remove the <!.. ..> that surrounds them. You
  will also need to set the passwords to something appropriate.
-->
<!--
  <user username="admin" password="<must-be-changed>" roles="manager-gui"/>
  <user username="robot" password="<must-be-changed>" roles="manager-script"/>
-->
<!--
  The sample user and role entries below are intended for use with the
  examples web application. They are wrapped in a comment and thus are ignored
  when reading this file. If you wish to configure these users for use with the
  examples web application, do not forget to remove the <!.. ..> that surrounds
  them. You will also need to set the passwords to something appropriate.
-->
<!--
  <role rolename="tomcat"/>
  <role rolename="role1"/>
  <user username="tomcat" password="<must-be-changed>" roles="tomcat"/>
  <user username="both" password="<must-be-changed>" roles="tomcat,role1"/>
  <user username="role1" password="<must-be-changed>" roles="role1"/>
-->
  <role rolename="manager"/>
  <role rolename="admin"/>
  <role rolename="manager-script"/>
  <role rolename="manager-gui"/>
  <user username="admin" password="Genesys2018!" roles="admin,manager,manager-script"/>
  <user username="tomcat" password="Genesys2018!" roles="manager-gui"/>
<!--
<role rolename="admin-gui,manager-gui"/>
<user username="admin" password="tomcat" roles="manager-gui,admin-gui"/>
-->

</tomcat-users>
' > tomcat-users.xml
echo tomcat-users.xml generado
echo 
echo Generando server.xml
echo '<?xml version="1.0" encoding="UTF-8"?>
<!--
  Licensed to the Apache Software Foundation (ASF) under one or more
  contributor license agreements.  See the NOTICE file distributed with
  this work for additional information regarding copyright ownership.
  The ASF licenses this file to You under the Apache License, Version 2.0
  (the "License"); you may not use this file except in compliance with
  the License.  You may obtain a copy of the License at

      http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
-->
<!-- Note:  A "Server" is not itself a "Container", so you may not
     define subcomponents such as "Valves" at this level.
     Documentation at /docs/config/server.html
 -->
<Server port="8005" shutdown="SHUTDOWN">
  <Listener className="org.apache.catalina.startup.VersionLoggerListener" />
  <!-- Security listener. Documentation at /docs/config/listeners.html
  <Listener className="org.apache.catalina.security.SecurityListener" />
  -->
  <!-- APR library loader. Documentation at /docs/apr.html -->
  <Listener className="org.apache.catalina.core.AprLifecycleListener" SSLEngine="on" />
  <!-- Prevent memory leaks due to use of particular java/javax APIs-->
  <Listener className="org.apache.catalina.core.JreMemoryLeakPreventionListener" />
  <Listener className="org.apache.catalina.mbeans.GlobalResourcesLifecycleListener" />
  <Listener className="org.apache.catalina.core.ThreadLocalLeakPreventionListener" />

  <!-- Global JNDI resources
       Documentation at /docs/jndi-resources-howto.html
  -->
  <GlobalNamingResources>
    <!-- Editable user database that can also be used by
         UserDatabaseRealm to authenticate users
    -->
    <Resource name="UserDatabase" auth="Container"
              type="org.apache.catalina.UserDatabase"
              description="User database that can be updated and saved"
              factory="org.apache.catalina.users.MemoryUserDatabaseFactory"
              pathname="conf/tomcat-users.xml" />
  </GlobalNamingResources>

  <!-- A "Service" is a collection of one or more "Connectors" that share
       a single "Container" Note:  A "Service" is not itself a "Container",
       so you may not define subcomponents such as "Valves" at this level.
       Documentation at /docs/config/service.html
   -->
  <Service name="Catalina">

    <!--The connectors can use a shared executor, you can define one or more named thread pools-->
    <!--
    <Executor name="tomcatThreadPool" namePrefix="catalina-exec-"
        maxThreads="150" minSpareThreads="4"/>
    -->


    <!-- A "Connector" represents an endpoint by which requests are received
         and responses are returned. Documentation at :
         Java HTTP Connector: /docs/config/http.html
         Java AJP  Connector: /docs/config/ajp.html
         APR (HTTP/AJP) Connector: /docs/apr.html
         Define a non-SSL/TLS HTTP/1.1 Connector on port 8080
    -->
    <Connector port="8080" protocol="HTTP/1.1"
               connectionTimeout="20000"
               redirectPort="8443" />
    <!-- A "Connector" using the shared thread pool-->
    <!--
    <Connector executor="tomcatThreadPool"
               port="8080" protocol="HTTP/1.1"
               connectionTimeout="20000"
               redirectPort="8443" />
    -->
    <!-- Define an SSL/TLS HTTP/1.1 Connector on port 8443
         This connector uses the NIO implementation. The default
         SSLImplementation will depend on the presence of the APR/native
         library and the useOpenSSL attribute of the
         AprLifecycleListener.
         Either JSSE or OpenSSL style configuration may be used regardless of
         the SSLImplementation selected. JSSE style configuration is used below.
    -->
    <!--
    <Connector port="8443" protocol="org.apache.coyote.http11.Http11NioProtocol"
               maxThreads="150" SSLEnabled="true">
        <SSLHostConfig>
            <Certificate certificateKeystoreFile="conf/localhost-rsa.jks"
                         type="RSA" />
        </SSLHostConfig>
    </Connector>
    -->
    <Connector port="8443" protocol="org.apache.coyote.http11.Http11Protocol"
               maxThreads="150" SSLEnabled="true" scheme="https" secure="true"
               clientAuth="false" sslProtocol="TLS"
               keystoreFile="/opt/cert/horwors.jks"
               keystorePass="Genesys2018!" />
    <!-- Define an SSL/TLS HTTP/1.1 Connector on port 8443 with HTTP/2
         This connector uses the APR/native implementation which always uses
         OpenSSL for TLS.
         Either JSSE or OpenSSL style configuration may be used. OpenSSL style
         configuration is used below.
    -->
    <!--
    <Connector port="8443" protocol="org.apache.coyote.http11.Http11AprProtocol"
               maxThreads="150" SSLEnabled="true" >
        <UpgradeProtocol className="org.apache.coyote.http2.Http2Protocol" />
        <SSLHostConfig>
            <Certificate certificateKeyFile="conf/localhost-rsa-key.pem"
                         certificateFile="conf/localhost-rsa-cert.pem"
                         certificateChainFile="conf/localhost-rsa-chain.pem"
                         type="RSA" />
        </SSLHostConfig>
    </Connector>
    -->

    <!-- Define an AJP 1.3 Connector on port 8009 -->
    <!--
    <Connector protocol="AJP/1.3"
               address="::1"
               port="8009"
               redirectPort="8443" />
    -->

    <!-- An Engine represents the entry point (within Catalina) that processes
         every request.  The Engine implementation for Tomcat stand alone
         analyzes the HTTP headers included with the request, and passes them
         on to the appropriate Host (virtual host).
         Documentation at /docs/config/engine.html -->

    <!-- You should set jvmRoute to support load-balancing via AJP ie :
    <Engine name="Catalina" defaultHost="localhost" jvmRoute="jvm1">
    -->
    <Engine name="Catalina" defaultHost="localhost">

      <!--For clustering, please take a look at documentation at:
          /docs/cluster-howto.html  (simple how to)
          /docs/config/cluster.html (reference documentation) -->
      <!--
      <Cluster className="org.apache.catalina.ha.tcp.SimpleTcpCluster"/>
      -->

      <!-- Use the LockOutRealm to prevent attempts to guess user passwords
           via a brute-force attack -->
      <Realm className="org.apache.catalina.realm.LockOutRealm">
        <!-- This Realm uses the UserDatabase configured in the global JNDI
             resources under the key "UserDatabase".  Any edits
             that are performed against this UserDatabase are immediately
             available for use by the Realm.  -->
        <Realm className="org.apache.catalina.realm.UserDatabaseRealm"
               resourceName="UserDatabase"/>
      </Realm>

      <Host name="localhost"  appBase="webapps"
            unpackWARs="true" autoDeploy="true">

        <!-- SingleSignOn valve, share authentication between web applications
             Documentation at: /docs/config/valve.html -->
        <!--
        <Valve className="org.apache.catalina.authenticator.SingleSignOn" />
        -->

        <!-- Access log processes all example.
             Documentation at: /docs/config/valve.html
             Note: The pattern used is equivalent to using pattern="common" -->
        <Valve className="org.apache.catalina.valves.AccessLogValve" directory="logs"
               prefix="localhost_access_log" suffix=".txt"
               pattern="%h %l %u %t &quot;%r&quot; %s %b" />

      </Host>
    </Engine>
  </Service>
</Server>
' > server.xml
echo server.xml generado
echo 
echo -----------------
echo Reemplazo XMLs
echo -----------------
echo 
echo Borrando y Moviendo context.xml
rm /opt/genesys/apache-tomcat-8.5.72/webapps/manager/META-INF/context.xml
mv /opt/genesys/context.xml /opt/genesys/apache-tomcat-8.5.72/webapps/manager/META-INF/
echo Borrado y Movido context.xml
echo 
echo Borrando y Moviendo tomcat-users.xml
rm /opt/genesys/apache-tomcat-8.5.72/conf/tomcat-users.xml
mv /opt/genesys/tomcat-users.xml /opt/genesys/apache-tomcat-8.5.72/conf/
echo Borrado y Movido context.xml
echo
echo Borrando y Moviendo server.xml
rm /opt/genesys/apache-tomcat-8.5.72/conf/server.xml
mv /opt/genesys/server.xml /opt/genesys/apache-tomcat-8.5.72/conf/
echo Borrado y Movido server.xml
echo 
echo -----------------
echo Owner Tomcat
echo -----------------
echo 
echo Cambiando Owner 
chown $usuario. /opt/genesys/apache-tomcat-8.5.72 -R
echo 
echo Owner Cambiado
echo 
echo -----------------
echo Certificado y Balanceador.txt
echo -----------------
echo 
echo Se genera Carpeta de CERT y se mueve el mismo
mkdir /opt/cert
mv /opt/genesys/$cert /opt/cert/
chown $usuario. /opt/cert -R
chmod 755 /opt/cert/$cert
echo 
echo Se genero y copio /opt/cert y se cambia OWNER 
echo 
echo Agrego Balanceador.txt
echo 
echo $HOSTNAME > /opt/genesys/apache-tomcat-8.5.72/webapps/ROOT/balanceador.txt
chown $usuario. /opt/genesys/apache-tomcat-8.5.72/webapps/ROOT/balanceador.txt
chmod 755 /opt/genesys/apache-tomcat-8.5.72/webapps/ROOT/balanceador.txt
echo 
echo Se genero el archivo y se le brindo permisos Owner
echo 
echo -----------------
echo Arrancando TOMCAT y servicio
echo -----------------
/etc/init.d/genesys-was_$HOSTNAME start
systemctl enable genesys-was_$HOSTNAME
echo Servicio INICIADO
echo 
echo -----------------
echo Limpieza
echo -----------------
echo 
echo Arranca Limpieza
rm /opt/genesys/apache-tomcat-8.5.72.tar.gz
sleep 2
rm /opt/genesys/Tomcatwors.sh



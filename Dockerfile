# Imagen vacía
FROM scratch

# Añadimos el SO Debian a la raiz del contenedor
ADD debian-bullseye.tar.gz /

# Instalar los paquetes necesarios
RUN apt-get update && \
    apt-get install -y git gitweb apache2 openssh-server

# Configurar GitWeb
COPY gitweb.conf /etc/gitweb.conf

# Configurar Apache para GitWeb
COPY gitweb-apache.conf /etc/apache2/sites-available/gitweb.conf
RUN ln -s /etc/apache2/sites-available/gitweb.conf /etc/apache2/sites-enabled/gitweb.conf

# Habilitar los módulos de Apache necesarios para git-over-http
RUN a2enmod cgi alias env

# Configurar SSH y el usuario git
RUN mkdir /var/run/sshd \
    && adduser --disabled-password --gecos "Git User" git \
    && mkdir /var/git \
    && chown git:git /var/git \
    && mkdir /home/git/.ssh \
    && chmod 700 /home/git/.ssh \
    && touch /home/git/.ssh/authorized_keys \
    && chmod 600 /home/git/.ssh/authorized_keys
    
# Configurar el servidor git-web en Apache
RUN sed -i 's|/var/git|/usr/share/gitweb|g' /etc/apache2/sites-available/gitweb.conf

# Copiar la clave pública del usuario git para SSH
COPY git.pub /home/git/.ssh/authorized_keys
RUN chown git:git /home/git/.ssh/authorized_keys

# Exponer los puertos SSH y HTTP
EXPOSE 22 80

# Iniciar SSH y Apache en la ejecución del contenedor
CMD service ssh start && apache2ctl -D FOREGROUND

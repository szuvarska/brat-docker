# start from a base ubuntu image
FROM ubuntu:18.04
MAINTAINER Cass Johnston <cassjohnston@gmail.com>

# set users cfg file
ARG USERS_CFG=users.json

# Install pre-reqs
RUN apt-get update
RUN apt-get install -y curl vim sudo wget rsync
RUN apt-get install -y apache2
RUN apt-get install -y python2.7 python2.7-dev && \
    ln -s /usr/bin/python2.7 /usr/bin/python
RUN apt-get install -y supervisor
RUN apt-get install -y openssh-server  # Install SSH server
RUN apt-get clean
RUN rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*


# Configure SSH to allow root login and password authentication
RUN echo "PermitRootLogin yes" >> /etc/ssh/sshd_config && \
    echo "PasswordAuthentication yes" >> /etc/ssh/sshd_config

# Set up SSH
RUN mkdir /var/run/sshd  # Required directory for SSH
RUN echo 'root:password' | chpasswd  # Password should be replaced with sth more secure

# Fetch  brat
RUN mkdir /var/www/brat
RUN curl -L -o /var/www/brat/brat-1.3p1.tar.gz https://github.com/nlplab/brat/archive/refs/tags/v1.3p1.tar.gz && \
    tar -xvzf /var/www/brat/brat-1.3p1.tar.gz -C /var/www/brat && \
    rm /var/www/brat/brat-1.3p1.tar.gz

# create a symlink so users can mount their data volume at /bratdata rather than the full path
RUN mkdir /bratdata && mkdir /bratcfg
RUN chown -R www-data:www-data /bratdata /bratcfg 
RUN chmod o-rwx /bratdata /bratcfg
RUN ln -s /bratdata /var/www/brat/brat-1.3p1/data
RUN ln -s /bratcfg /var/www/brat/brat-1.3p1/cfg

# And make that location a volume
VOLUME /bratdata
VOLUME /bratcfg

ADD brat_install_wrapper.sh /usr/bin/brat_install_wrapper.sh
RUN chmod +x /usr/bin/brat_install_wrapper.sh

# Make sure apache can access it
RUN chown -R www-data:www-data /var/www/brat/brat-1.3p1/

COPY 000-default.conf /etc/apache2/sites-available/000-default.conf

# add the user patching script
ADD user_patch.py /var/www/brat/brat-1.3p1/user_patch.py

# Enable cgi
RUN a2enmod rewrite
RUN a2enmod cgi

# We can't use apachectl as an entrypoint because it starts apache and then exits, taking your container with it.
# Instead, use supervisor to monitor the apache process
RUN mkdir -p /var/log/supervisor

ADD supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# Open SSH port
EXPOSE 80 22
# Expose port 22 for SSH

CMD ["/usr/bin/supervisord"]






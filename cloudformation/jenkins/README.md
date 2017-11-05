# Jenkins via CloudFormation

Intro
-----

This YAML based CloudFormation templates does the following: -

1. AWS Auto-Scaling Group 

  Creates a min / max 1 auto-scaling group which creates a Jenkins master node instnace.  For example, if this instance get's accidentally terminated then the server is recreated.

2. S3 Backups

  Scheduled daily backups are performed on essential Jenkins assets, archived and uploaded to an AWS S3 bucket.  This enables a terminated server to be restored to what it was the day before.  Also, if the entire stack is deleted and a new stack Jenkins stack re-created then it will be restored to the latest S3 backup.  Because daily backups are save it's possible to go back to a point in time.

3. Monitoring

  Standard CloudWatch monitoring scripts are included to monitor disk usage / memory metrics.

4. Nginx Load balancer

  Includes an Nginx load balancer which ports data from the standard tomcat port `8080` to the standard HTTP `80` port.

5. Elastic IP Association 

  This enables easy DNS to an elastic IP via your DNS of choice.

6. Cloudwatch Logs

  Logs are automatically uplaoded to CloudWatch which can be examined if something goes wrong.


Pre-Reqs
--------

You may want to SSH into the instance after it's been created - this requires having a SSH key in place.

1. Create Key

  * AWS -> EC2 -> Key Pairs -> Click "Create Key Pair" button -> Set name e.g. "bob-aws-key"  
  
  * Download key to PC 
  
  *  Create private key (Windows)

    * Download putty.exe / puttygen.exe / pageant.exe (https://www.chiark.greenend.org.uk/~sgtatham/putty/latest.html) 
      and store all 3 somewhere e.g. c:\aws\keys

    * Open puttygen.exe then menu -> Conversations -> Import Key -> select file e.g. bob-key.pem
        * Now click "Save private key"

  * Put key in Pageant (Optional step)
  
    * To get pageant to load this key at start follow the steps in: -
        https://blog.shvetsov.com/2010/03/making-pageant-automatically-load-keys.html

    * NOTE (Windows 10) "Start Menu" is located at C:\Users\bob\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Startup
    
    * Steps are: -
      1. Create shortcut e.g. `Pageant` and set start in to `c:\aws\keys`. 
      2. Add new `ppk` key as a parameter.
      3. Actually run the shortcut now and ensure it runs as a task -> double click and ensure key is there.
        
3. Create S3 Backup Bucket

  * AWS -> S3 -> Create Bucket -> Name it e.g. `com.jenkins.backups` -> Select defaults for everything.

4. Create Elasic IP

  * You may have a free ElasticIP, if not then: -

    * AWS -> EC2 -> Elastic Ips -> Allocate New address

  * _(take a note of the Allocation Id)_


Install
-------

Once your SSH key and S3 backup bucket are in place you can the install the Jenkins CloudFormation stack: -

* AWS -> CloudFormation -> Create Stack -> Upload a template to Amazon S3

* Choose file and select `jenkins.yaml` template and click *Next*.  Specify: -

   1. **Stack name** - e.g. `Jenkins`
   2. **ElasticIpAllocationId** - Set this to an Allocation Id of a free Elastic IP.
   3. **KeyName** - select a free SSH key name (used to access instance)
   4. **S3 Bucket** - select a free S3 bucket.
   5. **S3 Prefix** - optional value which is set if more than 1 jenkins stack is required.
   6. **Volume Size** - set of jenkins disk in GB e.g. `100` (defaults to `8`).
   7. **VpcId** - select valid VPC.
   8. **PublicSubnets** - select valid public subnet of selected VPC.

* Options screen: -

  * Click `Next`.

* Review screen: -

  1. Select checkbox that acknowledges this template will create an IAM user.
  2. Click `Create` button.

After some time the stack should create successfully.  You can then access the jenkins server via your browser using the IP address associated with the Elastic IP selected earlier.


Inital Setup
------------

The first time Jenkins is accessed it will ask for you to `Unlock Jenkins`.  This requires you to SSH to the server (e.g. using `putty.exe` on Windows) again using the same IP as the server.

Once logged in run the following command: -

    sudo cat /var/lib/jenkins/secrets/initialAdminPassword

This will return something like: -

    fb8316d15a6339a5a76a400e089cd431

Insert this value into the browser from where you can install the recommended plug-ins or set which plugins you want to install.

You are now ready to use Jenkins!



Extra Steps
-----------

1. Test Backup

  If you want to test the backup capabilities you can either wait 24 hours or (if you're impatient) temporarily update the cron entry in the `/etc/cron.d/jenkins` file from ... 

      59 0 * * * 

  ... _to_ ...
  
      * * * * *

  This will run the backup every minute.  




Useful commands 
---------------

sudo su -s /bin/bash jenkins                 # switch to jenkins user

/usr/local/bin/jenkins-restore s3://com.jenkins.backups/ /var/lib/jenkins || true # ignore errors
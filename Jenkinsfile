@Library('github.com/glogiotatidis/jenkins-pipeline@more-commands')
def stage_deployed = false
def config

def stageDeploy(image) {
  stage("Stage") {
    deisLogin("https://deis.eu-west.moz.works", config.project.deis_credentials) {
      deisPull(config.project.deis_stage_app, image)
    }
  }
}

duct {
  node {
    stage("Prepare") {
      checkout scm
      setGitEnvironmentVariables()

      try {
        config = readYaml file: "jenkins.yml"
      }
      catch (e) {
        config = []
      }
      println "config ==> ${config}"

      if (!config || (config && config.pipeline && config.pipeline.enabled == false)) {
        println "Pipeline disabled."
      }
    }

    def docker_image_name = "${config.project.docker_name}:${GIT_COMMIT_SHORT}"

    stage("Build") {
      if (!dockerImageExists(docker_image_name)) {
        dockerImageBuild(docker_image_name, ["pull": true])
      }
      else {
        echo "Image ${docker_image_name} already exists."
      }
    }

    stage("Test") {
      parallel "lint": {
        dockerRun(docker_image_name, "flake8 careers")
      },
      "unittest": {
        def db_name = "mariadb-${env.GIT_COMMIT_SHORT}-${BUILD_NUMBER}"
        def args = [
          "docker_args": ("--name ${db_name} " +
                          "-e MYSQL_ALLOW_EMPTY_PASSWORD=yes " +
                          "-e MYSQL_DATABASE=careers"),
          "cmd": "--character-set-server=utf8mb4 --collation-server=utf8mb4_bin",
          "bash_wrap": false
        ]

        dockerRun("mariadb:10.0", args) {
          args = [
            "docker_args": ("--link ${db_name}:db " +
                            "-e CHECK_PORT=3306 -e CHECK_HOST=db")
          ]
          dockerRun("giorgos/takis", args)

          args = [
            "docker_args": ("--link ${db_name}:db " +
                            "-e 'DEBUG=False' " +
                            "-e 'ALLOWED_HOSTS=*' " +
                            "-e 'SECRET_KEY=foo' " +
                            "-e 'DATABASE_URL=mysql://root@db/careers' " +
                            "-e 'SECURE_SSL_REDIRECT=False'"),
            "cmd": "coverage run ./manage.py test"
          ]
          dockerRun(docker_image_name, args)
        }
      }
    }

    stage("Upload Images") {
      dockerImagePush(docker_image_name, "mozjenkins-docker-hub")
    }

    milestone()

    println BRANCH_NAME

    onBranch("master") {
      stageDeploy(docker_image_name)
      stage_deployed = true
    }

    onTag(/\d{4}\d{2}\d{2}.\d{1,2}/) {
      if (!stage_deployed) {
        stageDeploy()
      }
      timeout(time: 10, unit: 'MINUTES') {
        input("Push to Production on Deis US-West?")
      }
      stage ("Production Push (US-West)") {
        deisLogin(config.project.deis_usw, config.project.deis_credentials) {
          deisPull(config.project.deis_prod_app, docker_image_name)
        }
      }
      timeout(time: 10, unit: 'MINUTES') {
        input("Push to Production on Deis EU-West?")
      }
      stage ("Production Push (US-West)") {
        deisLogin(config.projects.deis_euw, config.project.deis_credentials) {
          deisPull(config.project.deis_prod_app, docker_image_name)
        }
      }

    }
  }
}

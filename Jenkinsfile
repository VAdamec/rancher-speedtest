#!/usr/bin/env groovy
properties([disableConcurrentBuilds(), pipelineTriggers([])])
node ('basic'){

    def RANGE_PROJECTS_URL = "https://rancher-ui.example.com/v2-beta/projects"
    def RANCHER_STACK_NAME = "speedtest"
    def duration = currentBuild.duration

    def getRangeCommandByEnv = { env, command ->
        return "set +x; STACKNAME=${RANCHER_STACK_NAME} VERSION=${env.version} DOMAIN=${env.domain} SCALE=${env.scale} \
                PERSISTENT_VOLUME=${env.volume} \
                /bin/rancher-compose --project-name ${RANCHER_STACK_NAME}${env.stack_name_suffix} \
                    --url ${RANGE_PROJECTS_URL}/${env.rancher_project} \
                    --access-key ${env.access_key} \
                    --secret-key ${env.secret_key} " + command
    }

    def sendGraphiteEvent = { what, tags ->
        build job: 'graphite-event', parameters: [
                string(name: 'WHAT', value: "${RANCHER_STACK_NAME} " + what), \
                string(name: 'DATA', value: "Deploy of ${RANCHER_STACK_NAME}${env.stack_name_suffix} tag ${env.BUILD_NUMBER}" + what), \
                string(name: 'TAGS', value: tags) \
            ], wait: false
    }

    def checkHealtStatus = { env ->
      return "set +x; rancher \
          --url ${RANGE_PROJECTS_URL}/${env.rancher_project} \
          --access-key ${env.access_key} \
          --secret-key ${env.secret_key} \
          --wait-state healthy wait ${RANCHER_STACK_NAME}${env.stack_name_suffix}"
    }

    def runTests = { env ->
      return "set +x; rancher \
          --url ${RANGE_PROJECTS_URL}/${env.rancher_project} \
          --access-key ${env.access_key} \
          --secret-key ${env.secret_key} \
          exec \
          ${RANCHER_STACK_NAME}${env.stack_name_suffix}-hastebin-1 /opt/run.sh"
    }

    def getTests = { env ->
      return "set +x; script -q -a speedtest_result.out -f -c \"rancher \
          --url ${RANGE_PROJECTS_URL}/${env.rancher_project} \
          --access-key ${env.access_key} \
          --secret-key ${env.secret_key} \
          exec -it ${RANCHER_STACK_NAME}${env.stack_name_suffix}-hastebin-1 cat /opt/tests/speedtest_result.xml\""
    }

    def secrets = [
        [
            $class: 'VaultSecret', path: 'secret/rancher', secretValues: [
                [$class: 'VaultSecretValue', envVar: 'PROD_ACCESS_KEY', vaultKey: 'PRODAKEY'],
                [$class: 'VaultSecretValue', envVar: 'PROD_SECRET_KEY', vaultKey: 'PRODSKEY']
            ]
        ]
    ]

    def components = [
        [
            name: "hastebin",
            image: "demo/${RANCHER_STACK_NAME}-hastebin",
            dir: "hastebin",
        ],
        [
            name: "redis",
            image: "demo/${RANCHER_STACK_NAME}-redis",
            dir: "redis",
        ],
    ]

    def prod_env = [
        domain: "speedtest.apps.example.com",
        scale: "1",
        rancher_project: "1a5",
        volume: "/data/${RANCHER_STACK_NAME}-prod",
        volume_db: "/data/${RANCHER_STACK_NAME}db-prod",
        version: "${env.BUILD_NUMBER}",
        tag: "prod",
        access_key: "${env.PROD_ACCESS_KEY}",
        secret_key: "${env.PROD_SECRET_KEY}",
        stack_name_suffix: "-prod"
    ]

    def environments = [
        prod: prod_env,
    ]

    wrap([$class: 'VaultBuildWrapper', vaultSecrets: secrets]) {
        environments.prod.access_key = "${PROD_ACCESS_KEY}"
        environments.prod.secret_key = "${PROD_SECRET_KEY}"
    }

    stage('Workspace preparation') {
        checkout scm
        sh "sed -ie 's/build:.*//g' docker-compose.yml"
        sh "rm -f .env"
        sh 'rm -f speedtest_result.out speedtest_result.xml'
    }

    stage('Build Stable/Prod Docker Images') {
        def stepsForParallel = [:]
        for (int i = 0; i < components.size(); i++) {
            def s = components.get(i)
            def stepName = "echoing ${s}"
            stepsForParallel[stepName] = BuildImagesParallel(s.image,s.dir,environments.prod.version,environments.prod.tag)
        }

      try {
          parallel stepsForParallel
          currentBuild.result = 'SUCCESS'
        } catch (e) {
          currentBuild.result = "FAILED"
          sendGraphiteEvent("failed", "speedtest")
          throw error
        }
    }

    stage('Remove actuall Prod') {
      try {
        timeout(time: 360, unit: 'SECONDS') {
          sh getRangeCommandByEnv(environments.prod, "rm")
          currentBuild.result = 'SUCCESS'
        }
      } catch (e) {
        currentBuild.result = "FAILED"
        sendGraphiteEvent("failed", "speedtest")
      }
    }

    stage('Deploy Prod') {
      try {
        timeout(time: 360, unit: 'SECONDS') {
          sh getRangeCommandByEnv(environments.prod, "up -d --force-upgrade --pull --confirm-upgrade")
          currentBuild.result = 'SUCCESS'
        }
      } catch (e) {
        currentBuild.result = "FAILED"
        sendGraphiteEvent("failed", "speedtest")
      }
    }

    stage('Test PROD deployment status') {
      try {
        timeout(time: 360, unit: 'SECONDS') {
          sh checkHealtStatus(environments.prod)
          currentBuild.result = 'SUCCESS'
        }
      } catch (e) {
        currentBuild.result = "FAILED"
        sendGraphiteEvent("failed", "speedtest")
      }
    }

    stage('Testing') {
        try {
            sh runTests(environments.prod)
            sleep 5
            sh getTests(environments.prod)
            sleep 5
            sh 'grep -v "Script started" speedtest_result.out > speedtest_result.xml'
        } catch (error) {
            currentBuild.result = "FAILED"
            sendGraphiteEvent("failed", "speedtest")
            throw error
        }
    }

     stage("Archive tests"){
        junit allowEmptyResults: false, testResults: 'speedtest_result.xml'
     }
}

def BuildImagesParallel(image,path,version,tag) {
  return {
    timeout(time: 600, unit: 'SECONDS') {
      docker.withRegistry('https://registry.example.com', 'regcreds5000') {
        dir("${path}") {
          retry(3){
            def app = docker.build("${image}")
            app.push "${version}"
            app.push "${tag}"
          }
        }
      }
    }
  }
}

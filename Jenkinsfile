// pipeline {
//   agent any
//   stages {
//     environment {
//       //Use Pipeline Utility Steps plugin to read information from pom.xml into env variables
//       TEST_DB_NAME = sh('jenkins_example_$(cat /dev/urandom | env LC_CTYPE=C tr -dc "a-zA-Z0-9" | fold -w 5 | head -n 1)')
//       TEST_PORT = sh('$((3000 + RANDOM % 1000))')
//     }
//     stage ('Checkout') {
//       checkout scm
//     }
//     stage ('Install Gems') {
//       rvmSh 'whoami'
//       rvmSh 'which ruby'
//       rvmSh 'whereis rvm'
//       rvmSh 'which bundle'
//       rvmSh 'bundle install --path vendor/bundle --full-index --verbose'
//     }
//     stage ('Run Unit tests'){
//       sh 'printenv | sort'
//       rvmSh 'yarn install --check-files --ignore-engines'
//       rvmSh "export TMP_TEST_DB=jenkins_example_${env.BUILD_ID} && RAILS_ENV=test bundle exec rails db:create && RAILS_ENV=test bundle exec rails db:migrate && PORT=${(3000 + env.BUILD_ID)} && PORT=${(3000 + env.BUILD_ID)} CYPRESS_baseUrl=http://localhost:${(3000 + env.BUILD_ID)} yarn start-test 'start_test' 'http://localhost:${(3000 + env.BUILD_ID)}' cy:run && RAILS_ENV=test bundle exec rails db:drop"
//     }
//     if (env.BRANCH_NAME == 'master') {
//       stage ('Accept Staging Deployment') {
//         deploy = canDeploy()
//         if(deploy) {
//           stage 'Deploy to Staging'
//             echo 'Will deploy to Staging'
//         }
//       }
//     }
//     def tag = sh(returnStdout: true, script: "git tag --contains | head -1").trim()
//     if (tag) {
//       stage ('Accept Production Deployment') {
//         deploy = canDeploy()
//         if(deploy) {
//           stage 'Deploy to Production'
//             echo 'Will deploy to Production'
//         }
//       }
//     }
//   }
//   post {
//       always {
//         rvmSh "export TMP_TEST_DB=jenkins_example_${env.BUILD_ID} && RAILS_ENV=test bundle exec rails db:drop"
//       }
//       // failure {
//       //     mail to: nagarjuna.rachaneni@vandapharma.com, subject: 'The Pipeline failed :('
//       // }
//   }
// }

// def rvmSh(String cmd) {
//   final RVM_HOME = '$PATH:/var/lib/jenkins/.rvm/bin'
//   def sourceRvm = 'source /var/lib/jenkins/.rvm/scripts/rvm'
//   def useRuby = "/var/lib/jenkins/.rvm/bin/rvm use --install 2.5.3"
//   withEnv(["PATH=$PATH:/var/lib/jenkins/.rvm/bin"]) {
//     sh "${sourceRvm}; ${useRuby}; $cmd"
//   }
// }

// def canDeploy() {
//   when {
//     expression {
//       boolean deploy = false
//       try {
//         timeout(time: 1, unit: 'DAYS') {
//           input 'Let\'s deploy?'
//           deploy = true
//         }
//       } catch (final ignore) {
//         deploy = false
//       }
//       echo ('deploy:'+deploy)
//       return deploy
//     }
//   }
// }



node{
  try {
  environment {
    //Use Pipeline Utility Steps plugin to read information from pom.xml into env variables
    TEST_DB_NAME = sh('jenkins_example_$(cat /dev/urandom | env LC_CTYPE=C tr -dc "a-zA-Z0-9" | fold -w 5 | head -n 1)')
    TEST_PORT = sh('$((3000 + RANDOM % 1000))')
  }
    stage ('Checkout') {
      checkout scm
    }
    
    stage ('Install Gems') {
      rvmSh 'whoami'
      rvmSh 'which ruby'
      rvmSh 'whereis rvm'
      rvmSh 'which bundle'
      rvmSh 'bundle install --path vendor/bundle --full-index --verbose'
    }
    stage ('Run Unit tests'){
      sh 'printenv | sort'
      rvmSh 'yarn install --check-files --ignore-engines'
      rvmSh "export TMP_TEST_DB=jenkins_example_${env.BUILD_ID} && RAILS_ENV=test bundle exec rails db:create && RAILS_ENV=test bundle exec rails db:migrate && PORT=${(3000 + env.BUILD_ID.toInteger())} && PORT=${(3000 + env.BUILD_ID.toInteger())} CYPRESS_baseUrl=http://localhost:${(3000 + env.BUILD_ID.toInteger())} yarn start-test 'start_test' 'http://localhost:${(3000 + env.BUILD_ID.toInteger())}' cy:run"
    }
    
    
    if (env.BRANCH_NAME == 'master') {
      stage ('Accept Staging Deployment') {
        deploy = canDeploy()
        if(deploy) {
          stage 'Deploy to Staging'
            echo 'Will deploy to Staging'
        }
      }
    }
    def tag = sh(returnStdout: true, script: "git tag --contains | head -1").trim()
    if (tag) {
      stage ('Accept Production Deployment') {
        deploy = canDeploy()
        if(deploy) {
          stage 'Deploy to Production'
            echo 'Will deploy to Production'
        }
      }
    }
  }
  
  catch(err) {
    
    notifyCulpritsOnEveryUnstableBuild()
    currentBuild.result = 'FAILURE'
    throw err
  }

  finally {
    rvmSh "export TMP_TEST_DB=jenkins_example_${env.BUILD_ID} && RAILS_ENV=test bundle exec rails db:drop"
  }
}

def rvmSh(String cmd) {
    final RVM_HOME = '$PATH:/var/lib/jenkins/.rvm/bin'

    def sourceRvm = 'source /var/lib/jenkins/.rvm/scripts/rvm'
    def useRuby = "/var/lib/jenkins/.rvm/bin/rvm use --install 2.5.3"
    withEnv(["PATH=$PATH:/var/lib/jenkins/.rvm/bin"]) {
      // echo "${PATH}"
      sh "${sourceRvm}; ${useRuby}; $cmd"
    }
}

def notifyCulpritsOnEveryUnstableBuild() {
  step([
      $class                  : 'Mailer',
      notifyEveryUnstableBuild: true,
      recipients              : emailextrecipients([[$class: 'CulpritsRecipientProvider'], [$class: 'RequesterRecipientProvider']])
  ])
}

def canDeploy() {
    def deploy = input(id: 'deploy',
                                   message: 'Let\'s deploy?',
                                   parameters: [
                                     [$class: 'BooleanParameterDefinition', defaultValue: false, description: 'Deploy?', name: 'deploy']
                                   ])
    echo ('deploy:'+deploy)
  deploy
}

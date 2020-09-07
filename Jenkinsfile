
node('docker && magrathea') {
  stage('checkout') {
    checkout scm
  }

  stage('build and publish ui') {
    dir('ui') {
      docker.build('balrog/ui').inside() {
        withEnv([
          'BALROG_ROOT_URL=http://balrogadmin.ghosterydev.com',
          'AUTH0_DOMAIN=ghostery-balrog.eu.auth0.com',
          'AUTH0_CLIENT_ID=R1MYkSFRCgvtt2ItR6ZcV2dlEFyThXCT',
          'AUTH0_RESPONSE_TYPE=token id_token',
          'AUTH0_SCOPE=full-user-credentials openid profile email',
          'AUTH0_REDIRECT_URI=http://balrog-ui.ghosterydev.com.s3-website-us-east-1.amazonaws.com/login',
          'AUTH0_AUDIENCE=ghostery-balrog'
        ]) {
          sh 'yarn install'
          sh 'yarn build'
        }
      }
      withCredentials([[
        $class: 'AmazonWebServicesCredentialsBinding',
        accessKeyVariable: 'AWS_ACCESS_KEY_ID',
        credentialsId: '	04e892d6-1f78-400e-9908-1e9466e238a9',
        secretKeyVariable: 'AWS_SECRET_ACCESS_KEY'
      ]]) {
        sh 'aws s3 sync --acl public-read ./build/ s3://balrog-ui.ghosterydev.com/'
      }
    }
  }

  stage('push balrog image') {
    sh 'docker build -t balrog/balrog .'
    sh 'docker tag balrog/balrog:latest 470602773899.dkr.ecr.us-east-1.amazonaws.com/balrog/balrog:latest'
    withCredentials([[
      $class: 'AmazonWebServicesCredentialsBinding',
      accessKeyVariable: 'AWS_ACCESS_KEY_ID',
      credentialsId: '	04e892d6-1f78-400e-9908-1e9466e238a9',
      secretKeyVariable: 'AWS_SECRET_ACCESS_KEY'
    ]]) {
      sh 'aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin 470602773899.dkr.ecr.us-east-1.amazonaws.com'
      sh 'docker push 470602773899.dkr.ecr.us-east-1.amazonaws.com/balrog/balrog:latest'
    }
  }

  stage('push balrog agent image') {
    dir('agent') {
      withCredentials([[
        $class: 'AmazonWebServicesCredentialsBinding',
        accessKeyVariable: 'AWS_ACCESS_KEY_ID',
        credentialsId: '	04e892d6-1f78-400e-9908-1e9466e238a9',
        secretKeyVariable: 'AWS_SECRET_ACCESS_KEY'
      ], usernamePassword(
            credentialsId: 'dd3e97c0-5a9c-4ba9-bf34-f0071f6c3afa',
            passwordVariable: 'AUTH0_M2M_CLIENT_SECRET',
            usernameVariable: 'AUTH0_M2M_CLIENT_ID'
      )]) {
        sh "docker build --build-arg AUTH0_M2M_CLIENT_ID=${AUTH0_M2M_CLIENT_ID} --build-arg AUTH0_M2M_CLIENT_SECRET=${AUTH0_M2M_CLIENT_SECRET} -t balrog/agent ."
        sh 'docker tag balrog/agent:latest 470602773899.dkr.ecr.us-east-1.amazonaws.com/balrog/agent:latest'
        sh 'aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin 470602773899.dkr.ecr.us-east-1.amazonaws.com'
        sh 'docker push 470602773899.dkr.ecr.us-east-1.amazonaws.com/balrog/agent:latest'
      }
    }
  }

}
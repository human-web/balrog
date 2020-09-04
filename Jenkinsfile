
node('docker') {
  stage('checkout') {
    checkout scm
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
      sh 'docker build -t balrog/agent .'
      sh 'docker tag balrog/agent:latest 470602773899.dkr.ecr.us-east-1.amazonaws.com/balrog/agent:latest'
      withCredentials([[
        $class: 'AmazonWebServicesCredentialsBinding',
        accessKeyVariable: 'AWS_ACCESS_KEY_ID',
        credentialsId: '	04e892d6-1f78-400e-9908-1e9466e238a9',
        secretKeyVariable: 'AWS_SECRET_ACCESS_KEY'
      ]]) {
        sh 'aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin 470602773899.dkr.ecr.us-east-1.amazonaws.com'
        sh 'docker push 470602773899.dkr.ecr.us-east-1.amazonaws.com/balrog/agent:latest'
      }
    }
  }

}
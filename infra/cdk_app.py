from aws_cdk import (
    Stack,
    aws_lambda as lambda_,
    aws_apigateway as apigw
)
from constructs import Construct

class ApicultureStack(Stack):
    def __init__(self, scope: Construct, id: str, **kwargs):
        super().__init__(scope, id, **kwargs)
        fn = lambda_.Function(self, 'ApiFunction',
            runtime=lambda_.Runtime.PYTHON_3_9,
            handler='api.handler',
            code=lambda_.Code.from_asset('../api'),
            timeout=lambda_.Duration.seconds(30)
        )
        apigw.LambdaRestApi(self, 'ApiEndpoint', handler=fn)

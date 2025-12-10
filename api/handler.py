import json
from mangum import Mangum
from src.api.app import app
handler = Mangum(app)

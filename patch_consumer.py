import re

with open('lib/core/api_service.dart', 'r') as f:
    content = f.read()

pattern = r"""final queryUrl = url\.replace\(\s*queryParameters: \{\s*'consumer_key': consumerKey,\s*'consumer_secret': consumerSecret,\s*\},\s*\);"""

replacement = """final queryUrl = url.replace(
          queryParameters: {
            ...url.queryParameters,
            'consumer_key': consumerKey,
            'consumer_secret': consumerSecret,
          },
        );"""

content = re.sub(pattern, replacement, content)

with open('lib/core/api_service.dart', 'w') as f:
    f.write(content)


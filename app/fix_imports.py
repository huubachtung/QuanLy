import os
import re

for root, dirs, files in os.walk('lib'):
    for file in files:
        if file.endswith('.dart'):
            filepath = os.path.join(root, file)
            with open(filepath, 'r', encoding='utf-8') as f:
                content = f.read()
            
            content = re.sub(r"import\s+['\"].*?core/constants/app_colors\.dart['\"];", "import 'package:app/core/utils/app_colors.dart';", content)
            content = re.sub(r"import\s+['\"].*?app/theme\.dart['\"];", "import 'package:app/core/utils/theme.dart';", content)
            
            with open(filepath, 'w', encoding='utf-8') as f:
                f.write(content)

print('Done')

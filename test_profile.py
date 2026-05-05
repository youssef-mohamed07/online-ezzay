with open('lib/views/screens/profile_page.dart', 'r') as f:
    if "firstItem['image']" in f.read():
        print("Success")
    else:
        print("Failed")

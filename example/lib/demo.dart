class Demo {
  static String testPage(String str) {
    return """
<!DOCTYPE html>
<html lang="en">

<head>
    <meta charset="UTF-8">
    <meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>SALE INVOICE</title>


</head>

<body style='background-color: white;'>
    <h1 style='text-align:center'>Test Page => $str</h1>
    <br>
    <br>
</body>

</html>
   """;
  }
}

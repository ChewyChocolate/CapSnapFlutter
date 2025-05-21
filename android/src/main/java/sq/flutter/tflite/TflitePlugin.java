@Override
public void onMethodCall(MethodCall call, Result result) {
    if (call.method.equals("runModelOnImage")) {
        String imagePath = call.argument("path");
        // Return a dummy list as a placeholder
        List<Map<String, Object>> dummyResult = new ArrayList<>();
        Map<String, Object> item = new HashMap<>();
        item.put("label", "dummy_label");
        item.put("confidence", 0.99);
        dummyResult.add(item);
        result.success(dummyResult);
    } else {
        result.notImplemented();
    }
}
part of aliyun_oss_flutter;

class OSSClient {
  factory OSSClient() {
    return _instance!;
  }

  OSSClient._({
    required this.endpoint,
    required this.bucket,
    required this.credentials,
  }) {
    _signer = null;
  }

  /// * 初始化设置`endpoint` `bucket` `getCredentials`
  /// * [credentials] 获取 `Credentials`
  /// * 一旦初始化，则`signer`清空，上传前会重新拉取oss信息
  static OSSClient init({
    required String endpoint,
    required String bucket,
    required Future<Credentials> Function() credentials,
    Dio? dio,
  }) {
    _instance = OSSClient._(
      endpoint: endpoint,
      bucket: bucket,
      credentials: credentials,
    );
    if (dio != null) {
      _http = dio;
    }
    return _instance!;
  }

  static OSSClient? _instance;

  Signer? _signer;

  final String endpoint;
  final String bucket;
  final Future<Credentials> Function() credentials;

  /// * [bucket] [endpoint] 一次性生效
  /// * [path] 上传路径 如不写则自动以 Object[type] [time] 生成path
  Future<OSSObject> putObject({
    required OSSObject object,
    String? bucket,
    String? endpoint,
    String? path,
  }) async {
    _signer = await verify();

    final String objectPath = object.resourcePath(path);

    final Map<String, dynamic> safeHeaders = _signer!.sign(
      httpMethod: 'PUT',
      resourcePath: '/${bucket ?? this.bucket}/$objectPath',
      headers: {
        'content-type': object.mediaType.mimeType,
      },
    ).toHeaders();
    try {
      final String url =
          'https://${bucket ?? this.bucket}.${endpoint ?? this.endpoint}/$objectPath';
      final Uint8List bytes = object.bytes;
      // if (object is OSSImageObject && !object.fullImage) {
      //   bytes = MediaAssetUtils.compressImage(file);
      // }
      await _http.put<void>(
        url,
        data: Stream.fromIterable(bytes.map((e) => [e])),
        options: Options(
          headers: <String, dynamic>{
            ...safeHeaders,
            ...<String, dynamic>{
              'content-length': object.length,
            }
          },
          contentType: object._mediaType.mimeType,
        ),
        // onSendProgress: (int count, int total) {
        //   print(((count/total)*100).toStringAsFixed(2));
        // }
      );
      return object..uploadSuccessful(url);
    } catch (e) {
      rethrow;
    }
  }

  /// 验证检查
  Future<Signer> verify() async {
    // 首次使用
    if (_signer == null) {
      _signer = Signer(await credentials.call());
    } else {
      // 使用securityToken进行鉴权，则判断securityToken是否过期
      if (_signer!.credentials.useSecurityToken) {
        if (_signer!.credentials.expiration!.isBefore(DateTime.now().toUtc())) {
          _signer = Signer(await credentials.call());
        }
      } else {
        // expiration | securityToken中途丢失，则清空
        _signer!.credentials.clearSecurityToken();
      }
    }
    return _signer!;
  }
}
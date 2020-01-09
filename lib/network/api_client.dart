import 'dart:convert';
import 'dart:core';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:dio/adapter.dart';
import 'package:dio/dio.dart';
import 'package:intl/intl.dart';
import 'package:pixez/models/tags.dart';
import 'package:pixez/models/ugoira_metadata_response.dart';
import 'package:pixez/network/refresh_token_interceptor.dart';

class Restrict {
  static String PUBLIC = "public", PRIVATE = "private", ALL = "all";
}

class ApiClient {
  Dio httpClient;
  final String hashSalt =
      "28c1fdd170a5204386cb1313c7077b34f83e4aaf4aa829ce78c231e05b0bae2c";
  static const BASE_API_URL_HOST = 'app-api.pixiv.net';
  String getIsoDate() {
    DateTime dateTime = new DateTime.now();
    DateFormat dateFormat = new DateFormat("yyyy-MM-dd'T'HH:mm:ss'+00:00'");

    return dateFormat.format(dateTime);
  }

  static String getHash(String string) {
    var content = new Utf8Encoder().convert(string);
    var digest = md5.convert(content);
    return digest.toString();
  }

  ApiClient() {
    String time = getIsoDate();
    this.httpClient = Dio()
      ..options.baseUrl = "https://210.140.131.219"
      ..options.headers = {
        "X-Client-Time": time,
        "X-Client-Hash": getHash(time + hashSalt),
        "User-Agent": "PixivAndroidApp/5.0.155 (Android 6.0; Pixel C)",
        "Accept-Language": "zh-CN",
        "App-OS": "Android",
        "App-OS-Version": "Android 6.0",
        "App-Version": "5.0.166",
        "Host": BASE_API_URL_HOST
      }
      ..interceptors.add(LogInterceptor(requestBody: true, responseBody: true))
      ..interceptors.add(RefreshTokenInterceptor());
    (this.httpClient.httpClientAdapter as DefaultHttpClientAdapter)
        .onHttpClientCreate = (client) {
      HttpClient httpClient = new HttpClient();
      httpClient.badCertificateCallback =
          (X509Certificate cert, String host, int port) {
        return true;
      };
      return httpClient;
    };
  }

  Future<Response> getRecommend() async {
    return httpClient.get(
        "/v1/illust/recommended?filter=for_ios&include_ranking_label=true");
  }

  Future<Response> getUser(int id) async {
    return httpClient.get("/v1/user/detail?filter=for_android",
        queryParameters: {"user_id": id});
  }

  Future<Response> postUser(int a, String b) async {
    return httpClient.post("/v1/user",
        data: {"a": a, "b": b}..removeWhere((k, v) => v == null));
  }

  Map<String, dynamic> notNullMap(Map<String, dynamic> map) {
    return map..removeWhere((k, v) => v == null);
  }

//  @FormUrlEncoded
//  @POST("/v1/illust/bookmark/delete")
//  fun postUnlikeIllust(@Header("Authorization") paramString: String, @Field("illust_id") paramLong: Long): Observable<ResponseBody>
//
//  @FormUrlEncoded
//  @POST("/v2/illust/bookmark/add")
//  fun postLikeIllust(@Header("Authorization") paramString1: String, @Field("illust_id") paramLong: Long, @Field("restrict") paramString2: String, @Field("tags[]") paramList: List<String>?): Observable<ResponseBody>
  Future<Response> postLikeIllust(
      int illust_id, String restrict, List<String> tags) async {
    if (tags != null && tags.isNotEmpty)
      return httpClient.post("/v2/illust/bookmark/add",
          data: notNullMap({
            "illust_id": illust_id,
            "restrict": restrict,
            "tags[]": tags.toString() //null toString =="null"
          }),
          options: Options(contentType: Headers.formUrlEncodedContentType));
    else
      return httpClient.post("/v2/illust/bookmark/add",
          data: notNullMap({
            "illust_id": illust_id,
            "restrict": restrict,
          }),
          options: Options(contentType: Headers.formUrlEncodedContentType));
  }

  //postUnlikeIllust(@Header("Authorization") String paramString, @Field("illust_id") long paramLong);
  Future<Response> postUnLikeIllust(int illust_id) async {
    return httpClient.post("/v1/illust/bookmark/delete",
        data: {"illust_id": illust_id},
        options: Options(contentType: Headers.formUrlEncodedContentType));
  }

  Future<Response> getUnlikeIllust(int illust_id) async {
    return httpClient.get("/v1/illust/bookmark/delete?illust_id=$illust_id");
  }

  Future<Response> getNext(String url) async {
    String finalUrl = url.replaceAll("app-api.pixiv.net", "210.140.131.219");
    return httpClient.get(finalUrl);
  }

/*  @GET("/v1/illust/ranking?filter=for_android")
  fun getIllustRanking(@Header("Authorization") paramString1: String, @Query("mode") paramString2: String, @Query("date") paramString3: String?): Observable<IllustNext>*/
  Future<Response> getIllustRanking(String mode, date) async {
    return httpClient.get("/v1/illust/ranking?filter=for_android",
        queryParameters: notNullMap({
          "mode": mode,
          "date": date,
        }));
  }

//  @GET("/v1/user/illusts?filter=for_android")
//  fun getUserIllusts(@Header("Authorization") paramString1: String, @Query("user_id") paramLong: Long, @Query("type") paramString2: String): Observable<IllustNext>
  Future<Response> getUserIllusts(int user_id, String type) async {
    return httpClient.get("/v1/user/illusts?filter=for_android",
        queryParameters: {"user_id": user_id, "type": type});
  }

//  @GET("/v1/user/bookmarks/illust")
//  fun getLikeIllust(@Header("Authorization") paramString1: String, @Query("user_id") paramLong: Long, @Query("restrict") paramString2: String, @Query("tag") paramString3: String?): Observable<IllustNext>

  Future<Response> getBookmarksIllust(int user_id, String restrict, tag) async {
    return httpClient.get("/v1/user/bookmarks/illust",
        queryParameters:
            notNullMap({"user_id": user_id, "restrict": restrict, "tag": tag}));
  }

/*  @FormUrlEncoded
  @POST("/v1/user/follow/delete")
  fun postUnfollowUser(@Header("Authorization") paramString: String, @Field("user_id") paramLong: Long): Observable<ResponseBody>*/
  Future<Response> postUnFollowUser(int user_id) {
    return httpClient.post("/v1/user/follow/delete",
        data: {"user_id": user_id},
        options: Options(contentType: Headers.formUrlEncodedContentType));
  }

  // @GET("/v1/user/follower?filter=for_android")
  //   fun getUserFollower(@Header("Authorization") paramString: String, @Query("user_id") paramLong: Long): Observable<SearchUserResponse>
  Future<Response> getFollowUser(String restrict) {
    return httpClient.get(
      "/v1/user/follower?filter=for_android",
      queryParameters: {"restrict": restrict},
    );
  }

  //   @GET("/v2/illust/follow")
  // fun getFollowIllusts(@Header("Authorization") paramString1: String, @Query("restrict") paramString2: String): Observable<IllustNext>
  Future<Response> getFollowIllusts(String restrict) {
    return httpClient.get(
      "/v2/illust/follow",
      queryParameters: {"restrict": restrict},
    );
  }

  // @GET("/v1/user/following?filter=for_android")
  // fun getUserFollowing(@Header("Authorization") paramString1: String, @Query("user_id") paramLong: Long, @Query("restrict") paramString2: String): Observable<SearchUserResponse>
  Future<Response> getUserFollowing(int user_id, String restrict) {
    return httpClient.get(
      "/v1/user/following?filter=for_android",
      queryParameters: {"restrict": restrict, "user_id": user_id},
    );
  }

  //   @GET("/v2/search/autocomplete?merge_plain_keyword_results=true")
  // fun getSearchAutoCompleteKeywords(@Header("Authorization") paramString1: String, @Query("word") paramString2: String?): Observable<PixivResponse>
  Future<AutoWords> getSearchAutoCompleteKeywords(String word) async {
    final response = await httpClient.get(
      "/v2/search/autocomplete?merge_plain_keyword_results=true",
      queryParameters: {"word": word},
    );
    return AutoWords.fromJson(response.data);
  }

  //   @GET("/v1/trending-tags/illust?filter=for_android")
  // fun getIllustTrendTags(@Header("Authorization") paramString: String): Observable<TrendingtagResponse>
  Future<Response> getIllustTrendTags() async {
    return httpClient.get(
      "/v1/trending-tags/illust?filter=for_android",
    );
  }

  String getFormatDate(DateTime dateTime) {
    if (dateTime == null) {
      return null;
    } else
      return "${dateTime.year}-${dateTime.month}-${dateTime.day}";
  }

  //  @GET("/v1/search/illust?filter=for_android&merge_plain_keyword_results=true")
  // fun getSearchIllust(@Query("word") paramString1: String, @Query("sort") paramString2: String, @Query("search_target") paramString3: String?, @Query("bookmark_num") paramInteger: Int?, @Query("duration") paramString4: String?, @Header("Authorization") paramString5: String): Observable<SearchIllustResponse>
  Future<Response> getSearchIllust(String word,
      {String sort = null,
      String search_target = null,
      DateTime start_date = null,
      DateTime end_date = null,
      int bookmark_num = null}) async {
    return httpClient.get(
        "/v1/search/illust?filter=for_android&merge_plain_keyword_results=true",
        queryParameters: notNullMap({
          "sort": sort,
          "search_target": search_target,
          "start_date": getFormatDate(start_date),
          "end_date": getFormatDate(end_date),
          "bookmark_num": bookmark_num,
          "word": word
        }));
  }

  //   @GET("/v1/search/user?filter=for_android")
  // fun getSearchUser(@Header("Authorization") paramString1: String, @Query("word") paramString2: String): Observable<SearchUserResponse>
  Future<Response> getSearchUser(String word) async {
    return httpClient.get("/v1/search/user?filter=for_android",
        queryParameters: {"word": word});
  }

//  @GET("/v2/search/autocomplete?merge_plain_keyword_results=true")
//  fun getSearchAutoCompleteKeywords(@Header("Authorization") paramString1: String, @Query("word") paramString2: String?): Observable<PixivResponse>
  Future<Response> getSearchAutocomplete(String word) async =>
      httpClient.get("/v2/search/autocomplete?merge_plain_keyword_results=true",
          queryParameters: notNullMap({"word": word}));

/*
  @GET("/v2/illust/related?filter=for_android")
  fun getIllustRecommended(@Header("Authorization") paramString: String, @Query("illust_id") paramLong: Long): Observable<RecommendResponse>
*/
  Future<Response> getIllustRelated(int illust_id) async =>
      httpClient.get("/v2/illust/related?filter=for_android",
          queryParameters: notNullMap({"illust_id": illust_id}));

  //          @GET("/v2/illust/bookmark/detail")
  // fun getLikeIllustDetail(@Header("Authorization") paramString: String, @Query("illust_id") paramLong: Long): Observable<BookMarkDetailResponse>
  Future<Response> getIllustBookmarkDetail(int illust_id) async =>
      httpClient.get("/v2/illust/bookmark/detail",
          queryParameters: notNullMap({"illust_id": illust_id}));

  //          @FormUrlEncoded
  // @POST("/v1/user/follow/delete")
  // fun postUnfollowUser(@Header("Authorization") paramString: String, @Field("user_id") paramLong: Long): Observable<ResponseBody>
  Future<Response> postUnfollowUser(int user_id) async =>
      httpClient.post("/v1/user/follow/delete",
          data: notNullMap({"user_id": user_id}),
          options: Options(contentType: Headers.formUrlEncodedContentType));

/*  @FormUrlEncoded
  @POST("/v1/user/follow/add")
  fun postFollowUser(@Header("Authorization") paramString1: String, @Field("user_id") paramLong: Long, @Field("restrict") paramString2: String): Observable<ResponseBody>*/
  Future<Response> postFollowUser(int user_id, String restrict) {
    return httpClient.post("/v1/user/follow/add",
        data: {"user_id": user_id, "restrict": restrict},
        options: Options(contentType: Headers.formUrlEncodedContentType));
  }

/*
  @GET("/v1/illust/detail?filter=for_android")
  fun getIllust(@Header("Authorization") paramString: String, @Query("illust_id") paramLong: Long): Observable<IllustDetailResponse>
*/
  Future<Response> getIllustDetail(int illust_id) {
    return httpClient.get("/v1/illust/detail?filter=for_android",
        queryParameters: {"illust_id": illust_id});
  }

  //   @GET("/v1/spotlight/articles?filter=for_android")
  // fun getPixivisionArticles(@Header("Authorization") paramString1: String, @Query("category") paramString2: String): Observable<SpotlightResponse>
  Future<Response> getSpotlightArticles(String category) {
    return httpClient.get("/v1/spotlight/articles?filter=for_android",
        queryParameters: {"category": category});
  }

//  @GET("/v1/illust/comments")
//  fun getIllustComments(@Header("Authorization") paramString: String, @Query("illust_id") paramLong: Long): Observable<IllustCommentsResponse>
  Future<Response> getIllustComments(int illust_id) {
    return httpClient
        .get("/v1/illust/comments", queryParameters: {"illust_id": illust_id});
  }

  /* @FormUrlEncoded
  @POST("v1/illust/comment/add")
  fun postIllustComment(@Header("Authorization") paramString1: String, @Field("illust_id") illust_id: Long, @Field("comment") comment: String, @Field("parent_comment_id") parent_comment_id: Int?): Observable<ResponseBody>
*/
  Future<Response> postIllustComment(int illust_id, String comment,
      {int parent_comment_id = null}) {
    return httpClient.post("/v1/illust/comment/add",
        data: notNullMap({
          "illust_id": illust_id,
          "comment": comment,
          "parent_comment_id": parent_comment_id
        }),
        options: Options(contentType: Headers.formUrlEncodedContentType));
  }

//
//  @GET("/v1/ugoira/metadata")
//  fun getUgoiraMetadata(@Header("Authorization") paramString: String, @Query("illust_id") paramLong: Long): Observable<UgoiraMetadataResponse>
  Future<UgoiraMetadataResponse> getUgoiraMetadata(int illust_id) async {
    final result = await httpClient.get(
      "/v1/ugoira/metadata",
      queryParameters: notNullMap({"illust_id": illust_id}),
    );
    return UgoiraMetadataResponse.fromJson(result.data);
  }
}

import 'dart:convert';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../main.dart';

class RegionList extends StatefulWidget {
  /* 지역별 주유소 리스트. */
  final String region, regionName;
  const RegionList({super.key, required this.region, required this.regionName});

  @override
  State<RegionList> createState() => _RegionListState();
}

class _RegionListState extends State<RegionList> {
  /* 지역별 주유소 리스트. */
  static Future loadJson() async {
    final String response = await rootBundle.loadString(
        "assets/list/fullerstations.json"); /* TODO 데이터 파일 경로 확인하기! */
    final data = await json.decode(response);
    return data;
  }

  Future SAList = loadJson();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: Icon(
              Icons.arrow_back_ios,
              color: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
          title: Text(
            widget.regionName,
            style: TextStyle(
              color: Colors.white,
            ),
          ),
          backgroundColor: const Color.fromARGB(255, 255, 189, 89),
        ),
        floatingActionButton: FloatingActionButton(
            onPressed: () {
              Navigator.pushReplacement(
                context,
                // ignore: prefer_const_constructors
                MaterialPageRoute(builder: (context) => MyApp()),
              );
            },
            backgroundColor: const Color(0xffffbd59),
            child: const Icon(Icons.home, color: Colors.white)),
        body: FutureBuilder(
            future: SAList,
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                int SAcount = snapshot.data['list'].length;
                List<dynamic> foundSAList = [];
                List<dynamic> onlySAList = []; /* 휴게소만 */
                List<dynamic> onlyOilList = []; /* 주유소만 */
                int i;
                for (i = 0; i < SAcount; i++) {
                  if (snapshot.data['list'][i]['svarAddr']
                          .toString()
                          .startsWith(RegExp(widget.region)) &&
                      (snapshot.data['list'][i]['svarNm']
                              .toString()
                              .substring(0, 3) !=
                          "테스트")) {
                    foundSAList.add(snapshot.data['list'][i]);
                    if (snapshot.data['list'][i]['svarGsstClssNm'] == "휴게소") {
                      onlySAList.add(snapshot.data['list'][i]);
                    } else if (snapshot.data['list'][i]['svarGsstClssNm'] ==
                        "주유소") {
                      onlyOilList.add(snapshot.data['list'][i]);
                    }
                  }
                }
                List<dynamic> displayList = onlyOilList;
                if (displayList.isNotEmpty) {
                  return ListView.builder(
                    itemCount: displayList.length,
                    itemBuilder: (context, index) {
                      return ListTile(
                          title: Text(
                              "<${displayList[index]['routeNm']} ${displayList[index]['gudClssNm']}> ${displayList[index]['svarNm']}"),
                          onTap: () {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => TestDetailPage(
                                        SACode: displayList[index]['svarCd'],
                                        SAName: displayList[index]['svarNm'])));
                          });
                    },
                  );
                } else {
                  return Center(
                      child: Text("${widget.regionName}에서 휴게소를 찾지 못했습니다."));
                }
              } else if (snapshot.hasError) {
                return const Center(
                  child: Text("error..."),
                );
              } else {
                return const Center(
                  child: CircularProgressIndicator(strokeWidth: 2),
                );
              }
            }));
  }
}

class TestDetailPage extends StatelessWidget {
  /* 주유소 상세 페이지 */
  /* 주유소 상세 페이지. 이름은 test이지만, 더 이상 test가 아니다. */
  final String SACode, SAName;
  const TestDetailPage({super.key, required this.SACode, required this.SAName});

  static Future<http.Response> getSAData(SACode) async {
    final resp = http.get(Uri.parse(
        "http://data.ex.co.kr/openapi/business/curStateStation?key=test&type=json&numOfRows=10&pageNo=1&serviceAreaCode2=$SACode"));
    return resp;
  }

  Future<void> updateFav(String code, {bool remove = false}) async {
//    final SharedPreferences prefs = await _prefs;
    if (!remove) {
      if (sp.getStringList("favorite") != null) {
        List<String> favCodes = sp.getStringList("favorite")!;
        favCodes.add(code);
        sp.setStringList("favorite", favCodes);
      } else {
        sp.setStringList("favorite", [code]);
      }
    } else {
      if (sp.getStringList("favorite") != null) {
        List<String> favCodes = sp.getStringList("favorite")!;
        favCodes.remove(code);
        sp.setStringList("favorite", favCodes);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final SAData = getSAData(SACode);
    bool isFavorite = false;
    dynamic useIcon;
    if (favorite_list.indexWhere((f) => f["code"] == SACode) != -1) {
      isFavorite = true;
    }

    if (isFavorite) {
      useIcon = const Icon(Icons.star, semanticLabel: "즐겨찾기에 추가됨");
    } else {
      useIcon = const Icon(Icons.star_border, semanticLabel: "즐겨찾기에 추가");
    }

    return Scaffold(
        appBar: AppBar(
          title: Text(SAName),
          backgroundColor: const Color(0xffffbd59),
          foregroundColor: const Color(0xffffffff),
          actions: [
            IconButton(
              onPressed: () {
                if (!isFavorite) {
                  favorite_list.add({"code": SACode, "name": SAName});
                  isFavorite = true;
                  updateFav(SACode);
                  Fluttertoast.showToast(
                      msg:
                          "$SAName를 즐겨찾기에 추가했습니다."); /* 웹에서는 이 방식이 작동하지 않는데, Android와 iOS에선 작동한다고 한다. 어차피 안드로이드 앱이므로 상관없음. */
                } else {
                  favorite_list
                      .removeWhere((element) => element["code"] == SACode);
                  isFavorite = false;
                  updateFav(SACode, remove: true);
                  Fluttertoast.showToast(msg: "$SAName를 즐겨찾기에서 제거했습니다.");
                }
              },
              icon: useIcon,
              tooltip: "즐겨찾기",
            )
          ],
        ),
        floatingActionButton: FloatingActionButton(
            onPressed: () {
              Navigator.pushReplacement(
                context,
                // ignore: prefer_const_constructors
                MaterialPageRoute(builder: (context) => MyApp()),
              );
            },
            backgroundColor: const Color(0xffffbd59),
            child: const Icon(Icons.home, color: Colors.white)),
        body: FutureBuilder(
          future: SAData,
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              if (snapshot.data?.statusCode == 200) {
                final initialSAData = json.decode(snapshot.data!.body);
                dynamic RealSAData, GasText, DieText, LPGtext, LPGDisplay;
                Map<String, String> companyName = {
                  "HD": "현대오일뱅크",
                  "GS": "GS칼텍스",
                  "SK": "SK에너지",
                  "S": "S-OIL",
                  "AD": "알뜰주유소"
                };
                if (initialSAData['count'] == 0) {
                  return const Center(child: Text("휴게소 데이터가 존재하지 않습니다."));
                } else {
                  RealSAData = json.decode(snapshot.data!.body)['list'][0];
                }
                GasText = Text(
                  "휘발유 ${RealSAData['gasolinePrice']}",
                  style: const TextStyle(
                      color: Color(0xffaa2222), fontSize: 22.00),
                );
                DieText = Text(
                  "경유 ${RealSAData['diselPrice']}",
                  style: const TextStyle(
                      color: Color(0xff22aa22), fontSize: 22.00),
                );
                if (RealSAData['lpgYn'] == "Y") {
                  LPGtext = Text(
                    "LPG ${RealSAData['lpgPrice']}",
                    style: const TextStyle(
                        color: Color(0xff2222aa), fontSize: 22.00),
                  );
                  LPGDisplay = LPGDisplay = ColoredBox(
                      color: const Color(0x333333ff),
                      child: Center(
                        child: LPGtext,
                        heightFactor: 2.0,
                      ));
                } else {
                  LPGtext = const Text(
                    "LPG 없음",
                    style: TextStyle(
                        color: Color.fromARGB(96, 0, 0, 0), fontSize: 22.00),
                  );
                  LPGDisplay = ColoredBox(
                      color: const Color(0x00333333),
                      child: Center(child: LPGtext, heightFactor: 2.0));
                }
                return Padding(
                    padding: const EdgeInsets.fromLTRB(16, 36, 16, 36),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "${RealSAData['routeName']} ${RealSAData['direction']}방면 ${companyName[RealSAData['oilCompany'].toString()]}",
                          style: const TextStyle(fontSize: 16.00),
                        ),
                        Text("${RealSAData['serviceAreaName']}",
                            style: const TextStyle(fontSize: 40.00)),
                        Text("${RealSAData['svarAddr']}",
                            style: const TextStyle(fontSize: 16.00)),
                        Text("전화번호: ${RealSAData['telNo']}",
                            style: const TextStyle(fontSize: 16.00)),
                        Padding(
                            padding: const EdgeInsets.fromLTRB(0, 44, 0, 0),
                            child: ColoredBox(
                                color: const Color(0x33ff3333),
                                child: Center(
                                  child: GasText,
                                  heightFactor: 2.00,
                                ))),
                        ColoredBox(
                            color: const Color(0x3333ff33),
                            child: Center(
                              child: DieText,
                              heightFactor: 2.00,
                            )),
                        LPGDisplay
                      ],
                    ));
              } else {
                return Center(
                    child: Text(
                  "${snapshot.data?.statusCode} 응답을 받았습니다.",
                ));
              }
            } else if (snapshot.hasError) {
              return const Center(
                child: Text("error..."),
              );
            } else {
              return const Center(
                child: CircularProgressIndicator(strokeWidth: 2),
              );
            }
          },
        ));
  }
}

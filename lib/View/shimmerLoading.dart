import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class ShimmerLoading extends StatelessWidget {
  final double height;
  final double width;

  const ShimmerLoading({
    Key? key,
    this.height = 20.0,
    this.width = double.infinity,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child:  ListView.builder(
      itemCount: 3,
      itemBuilder: (context, index) {
        return ListTile(
          leading:CircleAvatar(),
          title: Container(
            height: 100,width: 200,
            color: Colors.white,
          ),
          subtitle: Container(
            height: 50,width: 100,
            color: Colors.white,
          ),
        );
      },
    ),
    );
  }
}

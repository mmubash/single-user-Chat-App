class MessageModel {
  String? conversation_id;
  String? sender_id;
  String? created_at;
  String? text;
  String? type;


  MessageModel(
      {
        this.conversation_id,
        this.sender_id,
        this.created_at,
        this.text,
        this.type,
        });

  MessageModel.fromJson(Map<String, dynamic> json) {
    this.conversation_id = json['conversation_id'].toString();
    this.sender_id = json['sender_id'].toString();
    this.created_at = json['created_at'];
    this.text = json['text'];
    this.type = json['type'];

  }


  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['conversation_id'] = this.conversation_id;
    data['sender_id'] = this.sender_id;
    data['created_at'] = this.created_at;
    data['text'] = this.text;
    data['type'] = this.type;
    return data;
  }
}

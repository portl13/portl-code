
output "staging_mongo_security_group_id" {
  value = "${aws_security_group.mongo.id}"
}

//output "staging_task_security_group_id" {
//  value = "${aws_security_group.task.id}"
//}
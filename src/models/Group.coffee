###
# Group schema
###

module.exports = (mongoose) ->
  Schema = mongoose.Schema
  ObjectId = Schema.ObjectId

  GroupSchema = new Schema
    name:
      type: String
      required: true
      index:
        unique: true
    identities: [
      type: ObjectId
      ref: 'Identity'
    ]
    attributes: {}
    updatedAt:
      type: Date
      default: Date.now
    createdAt:
      type: Date
      default: Date.now

  mongoose.model 'Group', GroupSchema

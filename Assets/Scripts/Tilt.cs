using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Tilt : MonoBehaviour
{
    Vector3 tilt = Vector2.zero;
    Vector3 initialEulerAngles;

    [SerializeField]
    float maxAngle = 45;

    // Start is called before the first frame update
    void Start()
    {
        initialEulerAngles = transform.rotation.eulerAngles;
    }

    // Update is called once per frame
    void Update()
    {
        float x = Input.GetAxis("Mouse X");
        float y = Input.GetAxis("Mouse Y");
        tilt.x += x;
        tilt.z += y;
        tilt.y = 0;
        Mathf.Clamp(tilt.x, -maxAngle, maxAngle);
        Mathf.Clamp(tilt.y, -maxAngle, maxAngle);

        transform.rotation = Quaternion.Euler(initialEulerAngles + tilt);
    }
}

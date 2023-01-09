using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Camera : MonoBehaviour
{
    float distance;

    [SerializeField]
    Transform far;

    [SerializeField]
    Transform near;

    private void Update()
    {
        float scroll = Input.GetAxis("Mouse ScrollWheel");
        distance = Mathf.Clamp(distance + scroll, 0, 1);

        transform.position = Vector3.Lerp(far.position, near.position, distance);
    }

}
